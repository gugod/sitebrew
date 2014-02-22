use v5.14;

package Sitebrew::Cmd::One {
    use Moose;
    use Text::Xslate;
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
        lazy_build => 1,
    );

    sub _build_html_file {
        my $self = shift;
        return $self->markdown_file =~ s/\.md$/.html/r =~ s/^content/public/r;
    }

    around 'BUILDARGS' => sub {
        my $orig = shift;
        my $class = shift;
        return $class->new(markdown_file => $_[0]) if @_ == 1 && !ref $_[0];
        return $class->$orig(@_);
    };

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

        Sitebrew::io($self->html_file)->assert->print($html);
    }
};
1;
