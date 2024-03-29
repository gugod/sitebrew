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
use List::AllUtils qw(any);
use Syntax::Keyword::Try;
use Path::Class;
use MCE::Loop;

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

    my $builder_sub = sub {
        my $article = shift;

        my $markdown_file = $article->content_file;
        my $html_file = $article->html_file;
        $html_file = Sitebrew::io($html_file);

        my $html_mtime = $html_file->exists() ? $html_file->mtime : undef;

        if ($opt->{force} || (! $html_file->exists)
            || (any { $html_mtime < $_ } Sitebrew::io($markdown_file)->mtime, @view_mtime)) {
            try {
                Sitebrew::App::Command::one::execute(undef, {}, [$markdown_file]);
                say "BUILD " . $markdown_file . " => " . $html_file;
            } catch($err) {
                warn "FAIL at building $markdown_file.\n$err\n";
            }
        }
    };

    my $articles_count = @articles;

    mce_loop {
        my $chunk_ref = $_[1];
        $builder_sub->( $_ ) for @$chunk_ref;
    } @articles;

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
