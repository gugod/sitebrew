use v5.14;
use utf8;

package Sitebrew::Cmd::Buildatom {
    use Moose;
    use XML::Feed;
    use Encode;
    use Sitebrew;
    use Sitebrew::Article;

    sub run {
        my @articles = Sitebrew::Article->first(25);
        my $brewer = Sitebrew->instance;
        my $feed = XML::Feed->new("Atom", version => 1.0);

        $feed->id($brewer->config->url_base->canonical->as_string);
        $feed->title($brewer->config->title);
        $feed->link($brewer->config->url_base);
        $feed->self_link($brewer->config->url_base . "/atom.xml");
        $feed->modified(DateTime->now);

        for my $article (@articles) {
            next if $article->content_file eq 'content/index.md';
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

        Sitebrew::io("public/atom.xml")->print( Encode::decode_utf8($feed->as_xml) );
        say "DONE: public/atom.xml";
    }
};
1;
