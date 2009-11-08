use inc::Module::Install;

name     'Seqsee';
all_from 'lib/Seqsee.pm';
author   q{Abhijit Mahabal <amahabal@gmail.com>};
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

