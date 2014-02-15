use v5.14;

package Sitebrew::Cmd::One {
    use Moose;

    use Text::Xslate;
    use IO::All -utf8;
    use YAML;
    use DateTime::Format::Mail;
    use Sitebrew;
    use Sitebrew::Article;

    has markdown_file => (
        is => "ro",
        isa => "Str",
        required => 1,
        documentation => "The markdown file to be processed."
    );

    has html_file => (
        is => "ro",
        isa => "Str",
        documentation => "The html file to be generated. Derived from `markdown_file` attribute.",
        default => sub {
            return $_[0]->markdown_file =~ s/\.md$/.html/r =~ s/^content/public/r;
        }
    );

    sub run {
        my $self = shift;
        my $article = Sitebrew::Article->new( content_file => $self->markdown_file );
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

        io($self->html_file)->assert->print($html);
    }
};
1;
