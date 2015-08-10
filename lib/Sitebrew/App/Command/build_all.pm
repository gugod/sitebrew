package Sitebrew::App::Command::build_all;
use v5.14;
use warnings;

use Sitebrew::App -command;
use Sitebrew::App::Command::one;

use Sitebrew;
use Sitebrew::Article;

use File::Find qw(find);
use File::Copy qw(copy);
use List::MoreUtils qw(any);
use Parallel::ForkManager;

sub opt_spec {
}

sub copy_assets {
    my $source = shift;
    my $destination = $source =~ s/^content/public/r;

    my $x = Sitebrew::io->file($destination);
    if ($x->exists && $x->mtime > Sitebrew::io($source)->mtime ) {
        # say "SKIP $source => $destination";
    }
    else {
        say "COPY $source => $destination";
        Sitebrew::io->dir("".file($destination)->parent)->mkpath;
        copy($source, $destination)
            or die "copy failed: $!";

        say "COPY $source => $destination";
    }
}

sub execute {
    my ($self, $opt) = @_;

    my @articles = Sitebrew::Article->all;

    my @view_mtime = ( Sitebrew::io("views/article.tx")->mtime );

    for (qw(article default)) {
        my $f = Sitebrew::io("views/$_-layout.tx");
        if ($f->exists) {
            push @view_mtime, $f->mtime
        }
    }

    my $builder_sub = sub {
        my $markdown_file = shift;
        my $html_file  = $markdown_file =~ s/\.md$/.html/r =~ s/^content/public/r;
        my $html_mtime = Sitebrew::io($html_file)->mtime;
        my $markdown_mtime = Sitebrew::io($markdown_file)->mtime;

        if (!-f $html_file || $markdown_mtime > $html_mtime || any { $html_mtime < $_ } @view_mtime) {
            Sitebrew::App::Command::one::execute(undef, {}, [$markdown_file]);
            say "BUILD " . $markdown_file . " => " . $html_file;
        } else {
            say "SKIP  " . $markdown_file;
        }
    };

    my $articles_count = @articles;
    my $worker_count = 8;
    my $forkman = Parallel::ForkManager->new( $worker_count );
    for (1..$worker_count) {
        my $pid = $forkman->start and next;
        for (my $i = 0; $i < $articles_count; $i += $worker_count) {
            $builder_sub->( $articles[$i]->content_file )
        }
        $forkman->finish;
    }
    $forkman->wait_all_children;

    find +{
        wanted => sub {
            return if !-f || /\.DS_Store/ || /\.git/ || /(\.md|_attributes\.yml)\z/ || $File::Find::dir =~ /(sass|\.git)/;
            copy_assets($File::Find::name);
        },
        no_chdir => 1,
        follow => 1
    }, "content";

    say 'ALL DONE';
}

1;
