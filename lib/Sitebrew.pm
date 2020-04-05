package Sitebrew;
# ABSTRACT: Static site builder.
use v5.14;
our $VERSION = "1.0";

use MooseX::Singleton;
use IO::All -utf8;
use Text::Markdown ();
use DateTime::TimeZone;
use DateTime::Format::Mail;
use DateTime::Format::ISO8601;
use Sitebrew::Config;
use Sitebrew::ContentContainer;
use Sitebrew::ContentIterator;
use Text::Xslate;

has site_root => (
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

sub _build_site_root {
    return io()->curdir->absolute->name;
}

sub _build_config {
    my $self = shift;
    my $config_file = io->catfile($self->site_root, ".sitebrew", "config.yml");
    if ($config_file->exists) {
        return Sitebrew::Config->load($config_file);
    } else {
        return Sitebrew::Config->new(
            title        => "Example Site",
            url_base     => "http://example.com",
            content_path => "content",
            public_path  => "public",
        );
    }
}

sub _build_local_time_zone {
    DateTime::TimeZone->new(name => 'local');
}

sub xslate {
    my ($self) = @_;

    my $site_root = $self->site_root;

    return Text::Xslate->new(
        input_layer => ":utf8",
        path => [
            $site_root . '/views',
            $site_root . '/layouts'
        ],
        function => $self->helpers,
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
            # I wish there's a special value to mean WHATEVER
            return [ Sitebrew::ContentIterator->latest($n // 9999999999) ];
        },

        format_datetime_mail => sub {
            my $o = shift or return '';
            return DateTime::Format::Mail->format_datetime($o);
        },

        format_datetime_iso8601 => sub {
            my $o = shift or return '';
            return DateTime::Format::ISO8601->format_datetime($o);
        },
    }
}

1;
