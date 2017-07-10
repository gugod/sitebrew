package Sitebrew::ContentIterator;
use Moose;

use Sitebrew;
use Sitebrew::ContentContainer;

sub first {
    my ($class, $count) = @_;
    $count ||= 1;

    if ($count < 1) {
        return ();
    }

    my @articles = $class->all;

    return splice(@articles, 0, $count);
}

sub all {
    my ($class) = @_;

    my @articles;

    $class->each(
        sub {
            push @articles, $_[0]
        }
    );

    return sort { $b->published_at <=> $a->published_at } @articles;
}


sub each {
    my ($class, $cb) = @_;
    my $site_root = Sitebrew->instance->site_root;

    my @content_files = sort { $b->mtime <=> $a->mtime } grep { /\.md$/ } Sitebrew::io->catdir($site_root, "content")->sort(0)->All_Files;

    for (@content_files) {
        my $x = Sitebrew::ContentContainer->new(content_file => $_->name);
        my $result = $cb->($x);
        last if defined($result) && !$result;
    }
}

1;
