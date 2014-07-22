use inc::Module::Install;
license('mit');
author('Kang-min Liu');
repository('https://github.com/gugod/sitebrew');
all_from("lib/Sitebrew.pm");
install_script("bin/sitebrew");
cpanfile();
makemaker_args( NORECURS => 1 );
WriteAll();
