package Sitebrew::Config;
use Moose;
use MooseX::Types::URI qw(Uri);

has title => (
    is => "rw",
    isa => "Str"
);

has url_base => (
    is => "rw",
    isa => Uri,
    required => 1,
    coerce => 1
);

has content_path => (
    is => "ro",
    isa => "Str",
    default => "content"
);

has public_path => (
    is => "ro",
    isa => "Str",
    default => "public"
);

has github_wiki => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
);

use namespace::autoclean;
use YAML::PP;

sub load {
    my ($class, $file) = @_;
    my $yaml = YAML::PP->new;
    my $config = $yaml->load_file($file);

    return $class->new(%$config);
}

no Moose;
1;
