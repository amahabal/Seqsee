use ExtUtils::MakeMaker;

sub MY::postamble{
  return <<"MAKE_FRAG";
smoke:
\t\tmake
\t\tperl util/run-smoke.pl . smoke.html
\t\tcp smoke.html /u/amahabal/.hyplan/smoke.html

TEST:
\t\tmake
\t\tcover -delete
\t\tHARNESS_PERL_SWITCHES=-MDevel::Cover make test
\t\tcover

MAKE_FRAG
}

WriteMakefile(
    NAME              => 'Seqsee',
    VERSION_FROM      => 'lib/Seqsee.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    test => { TESTS             => 't/*.t t/*/*.t t/*/*/*.t'},	      
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (
       AUTHOR         => 'Abhijit Mahabal <amahabal@cs.indiana.edu>',
      ) : ()),

);
