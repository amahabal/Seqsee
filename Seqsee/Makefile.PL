use inc::Module::Install;

name     'Seqsee';
all_from 'lib/Seqsee.pm';
author   q{Abhijit Mahabal <amahabal@gmail.com>};
license  'perl';

build_requires 'Test::More';

# I should clean this up as I remove dependencies.
requires 'Attribute::Handlers';
requires 'Carp::Source' => 0.03;
requires 'Class::Multimethods';
requires 'Class::Std';
requires 'Class::Std::Storable';
requires 'Config::Std';
requires 'Data::Dumper';
requires 'Exception::Class';
requires 'File::Slurp';
requires 'List::Util';
requires 'PerlIO';
requires 'Scalar::Util';
requires 'Smart::Comments';
requires 'Sort::Key' => 1.28;
requires 'Sub::Installer';
requires 'Test::Exception';
requires 'Test::Deep';
requires 'Test::Stochastic';
requires 'Time::HiRes';
requires 'Tk';
requires 'Tk::Carp';
requires 'Tk::ComboEntry';
requires 'Tk::Menustrip';
requires 'Tk::ROText';
WriteAll;

