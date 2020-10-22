package Sitebrew::App::Command::one;
#ABSTRACT: bulid one content (markdown file)
use v5.14;
use warnings;

use Sitebrew::App -command;

use Sitebrew;

sub opt_spec {
    return (
    );
}

sub execute {
    my ($self, $opt, $args) = @_;

    my $markdown_file = $args->[0];

    my $article = Sitebrew::ContentContainer->load( $markdown_file );
    my $html_file = $article->html_file;
    my $title = $article->title;

    my $tx = Sitebrew->xslate;
    my $html = $tx->render("article.tx", {
        article => {
            published_at => $article->published_at,
            created_at =>  $article->created_at,
            updated_at =>  $article->updated_at,
            title => $article->title,
            body_html => Text::Xslate::mark_raw(
                Sitebrew->markdown( $article->body )
            )
        },
        title => $title
    });

    Sitebrew::io($html_file)->assert->print($html);

}

1;
