package Sitebrew::ContentContainer;
use v5.14;

use Moose;
use utf8;
use YAML;
use File::stat;
use Digest::SHA1 qw(sha1_hex);
use Sitebrew;
use DateTime;
use DateTimeX::Easy;
use File::Slurp qw(read_file);
use Web::Query;
use URI;

has content_file => (
    is => "rw",
    isa => "Str",
    required => 1
);

has content_digest => (
    is => "rw",
    isa => "Str",
    lazy => 1,
    builder => "_build_content_digest"
);

has attributes => (
    is => "rw",
    isa => "HashRef",
    lazy_build => 1,
);

has title => (
    is => "rw",
    isa => "Str",
    lazy => 1,
    builder => "_build_title"
);

has body => (
    is => "rw",
    isa => "Str",
    lazy => 1,
    builder => "_build_body"
);

has published_at => (
    is => "rw",
    isa => "DateTime",
    lazy => 1,
    builder => "_build_published_at"
);

has href => (
    is => "rw",
    isa => "Str",
    lazy => 1,
    builder => "_build_href"
);

sub __load_file {
    my ($self) = @_;
    my $content = Sitebrew::io($self->content_file)->utf8->all;
    my ($front_part, $content_text);

    if (substr($content, 0, 4) eq "---\n") {
        ($front_part, $content_text) = split /\n---\n/, $content, 2;
    } else {
        $front_part = "---\n";
        $content_text = $content;
    }

    $content_text =~ s/\A\s+//;

    my $attr = YAML::Load($front_part) // {};

    my ($first_line) = $content_text =~ m/\A(.+)\n/;

    my $title = $first_line =~ s/^#+ //r;

    $content_text =~ s/\A(.+)\n//;
    $content_text =~ s/\A(=+)\n//;
    $content_text =~ s/\A\s+//s;

    $self->title($title);
    $self->body($content_text);
    $self->attributes($attr);
}

sub _build_title {
    my ($self) =  @_;
    $self->__load_file;
    return $self->title;
}

sub _build_body {
    my ($self) =  @_;
    $self->__load_file;
    return $self->body;
}

sub _build_attributes {
    my ($self) = @_;
    $self->__load_file;
    return $self->attributes;
}

sub _build_published_at {
    my $self = shift;
    my $attrs = $self->attributes;

    if (exists($attrs->{DATE})) {
        $attrs->{published_at} = DateTimeX::Easy->parse_datetime( $attrs->{DATE} );
    } else {
        $attrs->{published_at} = DateTime->from_epoch(
            epoch => stat($self->content_file)->mtime,
            time_zone => Sitebrew->local_time_zone,
        );
    }

    return $attrs->{published_at};
}

sub _build_href {
    my $self = shift;
    my $config = Sitebrew->instance->config;
    my $content_path = $config->content_path;

    my $url_base = $config->url_base;

    my $path = $self->content_file =~ s{^${content_path}/}{/}r =~ s/.md$/.html/r =~ s/\/index.html$/\//r;
    my $full_url = URI->new($url_base);
    $full_url->path($path);
    return "$full_url";
}

sub _build_content_digest {
    my $self = shift;
    my $data = read_file($self->content_file);
    return sha1_hex($data);
}

sub summary {
    my $self = shift;
    my $html = "<div>" . Sitebrew->markdown($self->body) . "</div>";
    my $dom = Web::Query->new_from_html( $html );
    return $dom->find("p")->first->text;
}

no Moose;
1;

=head1 NAME

Sitebrew::ContentContainer

=head1 DESCRIPTION

This ContentContainer object maps to a bunch of properties of a
markdown file. Each markdown file in the "content" directory is
mapped to an object of "ContentContainer".

To iterate over ContentContainer objects, see ContentIterator.

=cut
