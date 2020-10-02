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

    my $public_path = Sitebrew->config->public_path;
    my %existing;
    my $atom_path = $public_path . "/atom.xml";
    if (-f $atom_path) {
        open my $fh, "<", $atom_path;
        my $xml = XML::Feed->parse($fh);
        for my $entry ($xml->entries) {
            $existing{ $entry->id } = $entry;
        }
    }

    my @articles = Sitebrew::ContentIterator->latest(25);
    my $brewer = Sitebrew->instance;
    my $feed = XML::Feed->new("Atom", version => 1.0);

    $feed->id($brewer->config->url_base->canonical->as_string);
    $feed->title($brewer->config->title);
    $feed->link($brewer->config->url_base);
    $feed->self_link($brewer->config->url_base . "/atom.xml");

    my $latest_article_published_at = DateTime->from_epoch( epoch => 0 );
    my $content_path = Sitebrew->config->content_path;
    for my $article (@articles) {
        next if $article->content_file eq "${content_path}/index.md";
        my $id = $article->href . '?' . $article->content_digest;
        if ($existing{$id}) {
            $feed->add_entry($existing{$id});

            if ($existing{$id}->issued > $latest_article_published_at) {
                $latest_article_published_at = $existing{$id}->issued;
            }
        } else {
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
                $x->summary( $article->summary );

                my $t = $article->tags;
                if (@$t) {
                    $x->category(@$t);
                }

                $x;
            });
        }
    }

    $feed->modified( $latest_article_published_at );

    Sitebrew::io($atom_path)->print( Encode::decode_utf8($feed->as_xml) );
    say "DONE: ${atom_path}";
}

1;
