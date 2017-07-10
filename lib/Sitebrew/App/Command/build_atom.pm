package Sitebrew::App::Command::build_atom;
# ABSTRACT: build atom feed.

use v5.14;
use warnings;

use Sitebrew::App -command;

use XML::Feed;
use Encode;

use Sitebrew;
use Sitebrew::ContentIterator;

sub opt_spec {
    return (
    );
}

sub execute {
    my ($self, $opt) = @_;

    my $content_path = Sitebrew->config->content_path;
    my $public_path = Sitebrew->config->public_path;

    my @articles = Sitebrew::ContentIterator->first(25);
    my $brewer = Sitebrew->instance;
    my $feed = XML::Feed->new("Atom", version => 1.0);

    $feed->id($brewer->config->url_base->canonical->as_string);
    $feed->title($brewer->config->title);
    $feed->link($brewer->config->url_base);
    $feed->self_link($brewer->config->url_base . "/atom.xml");
    $feed->modified(DateTime->now);

    for my $article (@articles) {
        next if $article->content_file eq "${content_path}/index.md";
        $feed->add_entry(do {
            my $x = XML::Feed::Entry->new;
            $x->id($brewer->config->url_base . $article->href . '?' . $article->content_digest);
            $x->link($brewer->config->url_base . $article->href);
            $x->title($article->title);
            $x->modified($article->published_at);
            $x->author($ENV{USER});
            $x->summary( $article->summary );
            $x;
        });
    }

    my $atom_path = $public_path . "/atom.xml";
    Sitebrew::io($atom_path)->print( Encode::decode_utf8($feed->as_xml) );
    say "DONE: ${atom_path}";
}

1;
