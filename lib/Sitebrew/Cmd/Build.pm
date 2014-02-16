use v5.14;
package Sitebrew::Cmd::Build {
    use Moose;
    use IO::All -utf8;
    use Text::Xslate;
    use Sitebrew;

    has template => (
        is => "ro",
        isa => "Str",
        required => 1,
        documentation => "The root template to render."
    );

    around 'BUILDARGS' => sub {
        my $orig = shift;
        my $class = shift;

        if (@_ == 1 && !ref($_[0]) ) {
            return $class->$orig( template => $_[0] );
        }
        else {
            return $class->$orig(@_);
        }
    };

    sub run {
        my $self = shift;
        my $view_name = $self->template;

        my $tx = Text::Xslate->new(
            input_layer => ":utf8",
            path => ['views', 'layouts'],
            function => Sitebrew->helpers
        );

        my $html = $tx->render("${view_name}.tx");

        io("public/${view_name}.html")->print($html);

        return 1;
    }
};
1;
