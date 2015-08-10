package Sitebrew::App::Command::list;
use v5.14;
use warnings;

use Sitebrew::App -command;

use Sitebrew::Article;

sub opt_spec {
    return (
        [ "dry-run",   "Do not move the message, just display the result." ],
    );
}

sub execute {
    my ($self, $opt) = @_;

    binmode(STDOUT, ":utf8");
    for (Sitebrew::Article->all) {
        say $_->title;
        say "\t", $_->published_at;
        say "\t", $_->href;
        say "\t", $_->content_file;
        say "----";
    }

}

1;
