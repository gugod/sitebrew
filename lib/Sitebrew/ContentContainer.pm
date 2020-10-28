package Sitebrew::ContentContainer;
use v5.14;

use Moose;
use utf8;
use IO::All -utf8;
use YAML::PP;
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

has created_at => (
    is => "rw",
    isa => "Maybe[DateTime]",
    lazy => 1,
    builder => "_build_created_at"
);

has updated_at => (
    is => "rw",
    isa => "Maybe[DateTime]",
    lazy => 1,
    builder => "_build_updated_at"
);

has href => (
    is => "rw",
    isa => "Str",
    lazy => 1,
    builder => "_build_href"
);

has href_relative => (
    is => "rw",
    isa => "Str",
    lazy => 1,
    builder => "_build_href_relative"
);

has tags => (
    is => "ro",
    isa => "ArrayRef[Str]",
    lazy => 1,
    builder => "_build_tags",
);

sub load {
    my ($class, $file) = @_;
    my $obj = $class->new( content_file => $file );
    $obj->__load_file;
    return $obj;
}

sub __load_file {
    my ($self) = @_;
    my $content = io($self->content_file)->utf8->all;
    my ($front_part, $content_text);

    if (substr($content, 0, 4) eq "---\n") {
        ($front_part, $content_text) = split /\n---\n/, $content, 2;
    } else {
        $front_part = "---\n";
        $content_text = $content;
    }

    $content_text =~ s/\A\s+//;

    my $yaml = YAML::PP->new;
    my $attr = $yaml->load_string($front_part) // {};

    my $title;
    if (Sitebrew->config->github_wiki) {
        $title = io($self->content_file)->filename =~ s/\.md$//r =~ s/-/ /gr;
    } else {
        my ($first_line) = $content_text =~ m/\A(.+)\n/;
        $title = $first_line =~ s/^#+ //r;
        if (defined $title) {
            $content_text =~ s/\A(.+)\n//;
            $content_text =~ s/\A(=+)\n//;
            $content_text =~ s/\A\s+//s;
        }
    }

    $self->title($title);
    $self->body($content_text);
    $self->attributes($attr);

    my $eager = $self->updated_at;
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

sub _build_tags {
    my $self = shift;
    return [ split /[, \t]+/, ($self->attributes->{tags} // "") ];
}

sub _build_created_at {
    my $self = shift;
    return $self->__parse_datetime_attributes("created_at");
}

sub _build_updated_at {
    my $self = shift;
    return $self->__parse_datetime_attributes("updated_at");
}

sub _build_published_at {
    my $self = shift;
    return $self->__parse_datetime_attributes("published_at", "DATE") // $self->_content_file_mtime;
}

sub __parse_datetime_attributes {
    my ($self, @attributes) = @_;

    my $attrs = $self->attributes;

    my $t;
    for my $x (@attributes) {
        next unless exists $attrs->{$x};
        $t = DateTimeX::Easy->parse_datetime( $attrs->{$x} ) and last;
        warn "Attribute [$x] cannot be parsed as DateTime. [file=" . $self->content_file . "]\n";
    }

    return $t;
}

sub _content_file_mtime {
    my ($self) = @_;
    return DateTime->from_epoch(
        epoch => stat($self->content_file)->mtime,
        time_zone => Sitebrew->local_time_zone,
    );
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

sub _build_href_relative {
    my $self = shift;
    my $full_uri = URI->new( $self->href );
    return "" . $full_uri->path();
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

sub body_as_html {
    my $self = shift;
    return Sitebrew->markdown($self->body);
}

sub html_file {
    my $self = shift;
    my $content_path = Sitebrew->config->content_path;
    my $public_path = Sitebrew->config->public_path;
    my $html_file = $self->content_file =~ s/\.md$/.html/r =~ s/^\Q${content_path}\E/\Q${public_path}\E/r;
    return $html_file;
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
