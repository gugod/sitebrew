package Sitebrew::ContentIterator;
use Moose;

use Sitebrew;
use Sitebrew::ContentContainer;
use File::Next;


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
            push @articles, $_[0];
            return 1;
        }
    );

    return sort { $b->published_at <=> $a->published_at } @articles;
}

sub each {
    my ($class, $cb) = @_;
    my @content_files;

    my $site_root = Sitebrew->instance->site_root;

    my $content_dir = Sitebrew::io->catdir($site_root, "content");

    if ($content_dir->exists) {
        my $files = File::Next::files(
            +{
                descend_filter => sub { $_ ne '.git' },
                file_filter => sub { /\.md$/i }
            },
            "$content_dir",
        );
        while ( defined( my $file = $files->() ) ) {
            my $article = Sitebrew::ContentContainer->new(content_file => "$file");
            my $result = $cb->($article);
            last if defined($result) && !$result;
        }
    }
}

1;
