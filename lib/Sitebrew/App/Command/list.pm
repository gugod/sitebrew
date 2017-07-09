package Sitebrew::App::Command::list;
#ABSTRACT: list buildable contents
use v5.14;
use warnings;

use Sitebrew::App -command;

use Sitebrew::ContentContainer;

sub opt_spec {
    return (
        [ "site=s",   "A directory to your site." ],
        [ "dry-run",   "Do not move the message, just display the result." ],
    );
}

sub execute {
    my ($self, $opt) = @_;

    if ($opt->{site} && -d $opt->{site}) {
        $ENV{SITEBREW_ROOT} = $opt->{site};
    }

    binmode(STDOUT, ":utf8");
    for (Sitebrew::ContentContainer->all) {
        say $_->title;
        say "\t", $_->published_at;
        say "\t", $_->href;
        say "\t", $_->content_file;
        say "----";
    }

}

1;
