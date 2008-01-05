use 5.10.0;
use strict;
use lib 'genlib';
use English qw(-no_match_vars);
use S;

eval { SLTM->Load('memory_dump.dat') };
if ($EVAL_ERROR) {
    given ( ref($EVAL_ERROR) ) {
        when ('SErr::LTM_LoadFailure') {
            say "Failure in loading LTM: ", $EVAL_ERROR->what();
            exit;
        }
        say "In error handler: something failed! $EVAL_ERROR";
        exit;
    }
}
SLTM->init();

say "Nodes seen: $SLTM::NodeCount";
SLTM::Print();
