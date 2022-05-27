requires "App::Cmd" => 0;
requires "DateTime" => 0;
requires "DateTime::Format::Atom" => 0;
requires "DateTime::Format::Mail" => 0;
requires "DateTime::Format::ISO8601" => 0;
requires "DateTime::TimeZone" => 0;
requires "DateTimeX::Easy" => 0;
requires "Digest::SHA1" => 0;
requires "File::Slurp" => 0;
requires "IO::All" => 0;
requires "Moose" => 0;
requires "MooseX::Singleton" => 0;
requires "MooseX::Types::URI" => 0;
requires "Parallel::ForkManager" => 0;
requires "Markdent" => 0;
requires "Text::Xslate" => 0;
requires "URI" => 0;
requires "Web::Query" => 0;
requires "XML::Atom" => 0;
requires "XML::Feed" => 0;
requires "YAML::PP" => 0;
requires "namespace::autoclean" => 0;
requires "File::Next";
requires "MCE";
requires "Syntax::Keyword::Try";
requires "Path::Class";
requires "List::AllUtils";

on 'configure' => sub {
    requires "Module::Build";
};
