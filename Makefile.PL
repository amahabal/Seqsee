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

docs:
\t\tcd NaturalDocs; ./NaturalDocs -i /u/amahabal/SeqseeTree/summer05/lib -i /u/amahabal/SeqseeTree/summer05/Apps -i /u/amahabal/SeqseeTree/summer05/t -i /u/amahabal/SeqseeTree/summer05/util -i /u/amahabal/SeqseeTree/summer05/pod -o FramedHTML /u/amahabal/.hyplan/ND/ -p Proj 

pdfdocs:
\t\tcd NaturalDocs; ./NaturalDocs -i /u/amahabal/SeqseeTree/summer05/lib -i /u/amahabal/SeqseeTree/summer05/Apps -i /u/amahabal/SeqseeTree/summer05/t -i /u/amahabal/SeqseeTree/summer05/util -i /u/amahabal/SeqseeTree/summer05/pod -o PDF /tmp/Output -p Proj 
\t\tcd /tmp/Output; lmake Main

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
