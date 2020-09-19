package Sitebrew::App::Command::list;
#ABSTRACT: list buildable contents
use v5.14;
use warnings;

use Sitebrew::App -command;

use Sitebrew::ContentContainer;
use Sitebrew::ContentIterator;

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
    Sitebrew::ContentIterator->each(
        sub {
            local $_ = $_[0];
            say "title:\t" . $_->title;
            say "published_at: \t", $_->published_at // '(undef)';
            say "created_at: \t", $_->created_at // '(undef)';
            say "updated_at: \t", $_->updated_at // '(undef)';
            say "href: \t", $_->href;
            say "content_file: \t", $_->content_file;
            say "tags: \t", join(", ", @{ $_->tags });
            say "----";
        }
    );
}

1;
