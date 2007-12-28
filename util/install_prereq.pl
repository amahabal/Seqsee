use CPAN;

my @reqs = qw{
Class::Multimethods
Class::Std
Config::Std
Devel::StackTrace
Digest::MD5
Exception::Class
File::Basename
File::Glob
File::Slurp
File::Spec
File::Spec::Unix
File::Spec::Win32
Filter::Simple
Filter::Util::Call
Getopt::Long
List::Util
Log::Log4perl
Memoize
Module::Compile
POSIX
Perl6::Export
Perl6::Form
Scalar::Util
Smart::Comments
Sort::Key
Sub::Installer
Sub::Uplevel
Sys::Hostname
Test::Builder
Test::Deep
Test::Exception
Test::More
Test::Stochastic
Text::Balanced
Time::HiRes
Tk::Carp
Tk::MListbox
UNIVERSAL::require
XSLoader
enum
version
};

for my $mod (@reqs) {
    my $obj = CPAN::Shell->expand('Module',$mod);
    $obj->install;
}
