package Sitebrew::App::Command::build;
use v5.14;
use warnings;

use Sitebrew::App -command;

use Sitebrew;

sub opt_spec {
    return (
        [ "dry-run",   "Do not move the message, just display the result." ],
    );
}

sub execute {
    my ($self, $opt, $args) = @_;

    my $view_name = $args->[0];

    my $tx = Sitebrew->xslate;
    my $html = $tx->render("${view_name}.tx");

    Sitebrew::io("public/${view_name}.html")->print($html);
    return 1;
}

1;
