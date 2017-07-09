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
        Sitebrew->initialize( site_root => $opt->{site});
    }

    binmode(STDOUT, ":utf8");
    for (Sitebrew::ContentContainer->all) {
        say "title:\t" . $_->title;
        say "published_at: \t", $_->published_at;
        say "href: \t", $_->href;
        say "content_file: \t", $_->content_file;
        say "----";
    }

}

1;
