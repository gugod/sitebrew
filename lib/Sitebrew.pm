package Sitebrew;
# ABSTRACT: Static site builder.
use MooseX::Singleton;
use IO::All;
use Text::Markdown ();
use DateTime::TimeZone;
use Sitebrew::Config;
use Sitebrew::Article;
use Text::Xslate;

has app_root => (
    is => "ro",
    isa => "Str",
    lazy_build => 1,
);

has config => (
    is => "rw",
    isa => "Sitebrew::Config",
    lazy_build => 1
);

has local_time_zone => (
    is => "ro",
    isa => "DateTime::TimeZone",
    lazy_build => 1
);

sub _build_app_root {
    return $ENV{SITEBREW_ROOT} || io->curdir->absolute->name;
}

sub _build_config {
    my $self = shift;
    Sitebrew::Config->load( io->catfile($self->app_root, ".sitebrew", "config.yml") );
}

sub _build_local_time_zone {
    DateTime::TimeZone->new(name => 'local');
}

sub xslate {
    my ($self) = @_;

    return Text::Xslate->new(
        input_layer => ":utf8",
        path => ['views', 'layouts'],
        function => Sitebrew->helpers
    );
}

sub markdown {
    my ($self, $text, @options) = @_;

    # github markup
    $text =~ s{(?<!`)\[\[([^\n]+?)\]\](?!`)}{
        my $label = $1;
        my $page = $1 =~ s{ }{-}gr =~ s{/}{-}gr;

        "[$label]($page.html)"
    }eg;

    my $tm = Text::Markdown->new(empty_element_suffix => '>');
    return $tm->markdown($text);
}

sub helpers {
    my ($self) = @_;
    return {
        markdown => sub {
            my $t = shift;
            return Text::Xslate::mark_raw( Sitebrew->markdown($t) );
        },

        articles => sub {
            my $n = shift;

            if (defined($n) && $n > 0) {
                return [Sitebrew::Article->first($n)]
            }
            return [Sitebrew::Article->all]
        }
    }
}

1;
