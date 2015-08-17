package Sitebrew::App::Command::one;
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

    my $content_path = Sitebrew->config->content_path;
    my $public_path = Sitebrew->config->public_path;

    my $markdown_file = $args->[0];
    my $html_file = $markdown_file =~ s/\.md$/.html/r =~ s/^\Q${content_path}\E/\Q${public_path}\E/r;

    my $article = Sitebrew::Article->new( content_file => $markdown_file );
    my $title = $article->title;

    my $tx = Text::Xslate->new( path => ['views', 'layouts']);
    my $html = $tx->render("article.tx", {
        article => {
            published_at => DateTime::Format::Mail->format_datetime($article->published_at),
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
