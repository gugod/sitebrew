use v5.14;
use utf8;

package Sitebrew::Cmd::List {
    use Moose;

    sub run {
        binmode(STDOUT, ":utf8");
        for (Sitebrew::Article->all) {
            say $_->title;
            say "\t", $_->published_at;
            say "\t", $_->href;
            say "\t", $_->content_file;
            say "----";
        }
    }
};
1;
