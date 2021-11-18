package Sitebrew::App::Command::build_atom;
# ABSTRACT: build atom feed.

use v5.14;
use warnings;

use Sitebrew::App -command;

use Sitebrew;
use Sitebrew::ContentIterator;

use List::AllUtils qw( any );
use XML::Feed;
use XML::Feed::Entry;
use XML::Feed::Content;
use Encode;

sub opt_spec {
    return (
        [ "o=s",   "A output path of atom.xml" ],
        [ "category=s",   "A category name as the constraint" ],
    );
}

sub execute {
    my ($self, $opt) = @_;

    my $public_path = Sitebrew->config->public_path;

    my @articles = Sitebrew::ContentIterator->all;
    if ($opt->{category}) {
        @articles = grep { any { $opt->{category} eq $_ } @{$_->tags} } @articles;
    }
    @articles = sort { $b->published_at <=> $a->published_at } @articles;
    @articles = splice(@articles, 0, 25);

    my $brewer = Sitebrew->instance;
    my $feed = XML::Feed->new("Atom", version => 1.0);

    $feed->id($brewer->config->url_base->canonical->as_string);
    $feed->title($brewer->config->title);
    $feed->link($brewer->config->url_base);

    my $latest_article_published_at = DateTime->from_epoch( epoch => 0 );
    my $content_path = Sitebrew->config->content_path;
    for my $article (@articles) {
        next if $article->content_file eq "${content_path}/index.md";
        my $id = $article->href . '?' . $article->content_digest;

        if ($article->published_at > $latest_article_published_at) {
            $latest_article_published_at = $article->published_at;
        }

        $feed->add_entry(do {
            my $x = XML::Feed::Entry->new;
            $x->id($id);
            $x->link($article->href);
            $x->title($article->title);
            $x->issued($article->published_at);
            $x->author($ENV{USER});
            $x->content(
                XML::Feed::Content->new({
                    type => 'text/html',
                    body => $article->body_as_html,
                    base => $brewer->config->url_base,
                })
            );
            my $t = $article->tags;
            if (@$t) {
                $x->category(@$t);
            }
            $x;
        });

    }

    $feed->modified( $latest_article_published_at );
    my $atom_path = $opt->{o} || ($public_path . "/atom.xml");

    Sitebrew::io($atom_path)->print( Encode::decode_utf8($feed->as_xml) );
    say "DONE: ${atom_path}";
}

1;
