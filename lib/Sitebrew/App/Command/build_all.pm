package Sitebrew::App::Command::build_all;
# ABSTRACT: build all content

use v5.14;
use warnings;

use Sitebrew::App -command;
use Sitebrew::App::Command::one;

use Sitebrew;
use Sitebrew::ContentContainer;
use Sitebrew::ContentIterator;

use Path::Class qw(file);
use File::Find qw(find);
use File::Copy qw(copy);
use List::MoreUtils qw(any);
use Path::Class;

sub opt_spec {
    return (
        [ "force|f",   "Ignore the timestamp check and rebuild everything anyway." ],
        [ "dry-run",   "Do not build anything, just print the messages as if they are actually done." ],
    );
}

sub copy_assets {
    my ($source) = @_;

    my $content_path = Sitebrew->config->content_path;
    my $public_path = Sitebrew->config->public_path;
    my $destination = $source =~ s<^\Q${content_path}\E><\Q${public_path}\E>r;

    my $x = Sitebrew::io->file($destination);
    unless ($x->exists && $x->mtime > Sitebrew::io($source)->mtime ) {
        say "COPY $source => $destination";
        Sitebrew::io->dir("".file($destination)->parent)->mkpath;
        copy($source, $destination)
            or die "copy failed: $!";

        say "COPY $source => $destination";
    }
}

sub execute {
    my ($self, $opt) = @_;

    my @articles = Sitebrew::ContentIterator->all;

    my @view_mtime = ( Sitebrew::io("views/article.tx")->mtime );

    for (qw(article default)) {
        my $f = Sitebrew::io("views/$_-layout.tx");
        if ($f->exists) {
            push @view_mtime, $f->mtime
        }
    }

    my $content_path = Sitebrew->config->content_path;
    my $public_path = Sitebrew->config->public_path;
    my $builder_sub = sub {
        my $markdown_file = shift;
        my $html_file  = $markdown_file =~ s/\.md$/.html/r =~ s/^\Q${content_path}\E/\Q${public_path}\E/r;
        $html_file = Sitebrew::io($html_file);
        my $html_mtime = $html_file->exists() ? $html_file->mtime : undef;
        my $markdown_mtime = Sitebrew::io($markdown_file)->mtime;

        if ($opt->{force} || (! $html_file->exists) || ($markdown_mtime > $html_mtime) || (any { $html_mtime < $_ } @view_mtime)) {
            Sitebrew::App::Command::one::execute(undef, {}, [$markdown_file]);
            say "BUILD " . $markdown_file . " => " . $html_file;
        }
    };

    my $articles_count = @articles;
    for my $a (@articles) {
        $builder_sub->( $a->content_file );
    }

    find +{
        wanted => sub {
            return if !-f || /\.DS_Store/ || /\.git/ || /(\.md|\.attributes\.yml)\z/ || $File::Find::dir =~ /(sass|\.git)/;
            copy_assets($File::Find::name);
        },
        no_chdir => 1,
        follow => 1
    }, "content";

    say 'ALL DONE';
}

1;
