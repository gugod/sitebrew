use Module::Build;
use Module::Build::Prereqs::FromCPANfile;

Module::Build->new(
    "module_name" => "Sitebrew",
    "license" => "CC0",
    "script_files" => ["script/sitebrew"],
    mb_prereqs_from_cpanfile(),
)->create_build_script;
