package Sitebrew::App::Command::build;
# ABSTRACT: build one template.

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

    my $public_path = Sitebrew->config->public_path;
    Sitebrew::io("${public_path}/${view_name}.html")->print($html);
    return 1;
}

1;
