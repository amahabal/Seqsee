use strict;
use blib;
use Test::Seqsee;
plan tests => 6; 

use Smart::Comments;
use Seqsee;
use List::MoreUtils;

INITIALIZE_for_testing();

use Class::Multimethods;
multimethod 'find_reln';


sub attempt_extension{
    my ( $setup_sub, $expected_throws, $check_sub ) = @_;

    if ($check_sub) {
        confess ' defining a check_sub when there can be exceptions is useless.. ' unless List::MoreUtils::all { $_ eq '' } @$expected_throws;
    }

    code_throws_stochastic_all_and_only_ok
        sub {
            SUtil::clear_all();
            my $opts_ref = $setup_sub->();
            my $cl = new SCodelet('AttemptExtension', 100, $opts_ref );
            ## $cl
            $cl->run;
        }, $expected_throws;
    if ($check_sub) {
        ok( $check_sub->(), 'checking the after effects');
    } else {
        ok( 1, 'nothing to check' );

    }
}

Test::Stochastic::setup( times => 5);

attempt_extension (
    sub 
        {
            SWorkspace->init({seq => [qw( 1 1 1 2 2 2)]});
            my $WSO_ra = find_reln($SWorkspace::elements[0], $SWorkspace::elements[1]);
            $WSO_ra->insert();
            return { core => $WSO_ra, direction => DIR::RIGHT() };
        }, 
    [''],
    sub {
        my $rel = $SWorkspace::elements[1]->get_relation($SWorkspace::elements[2]);
        return $rel;
    }

        );


attempt_extension (
    sub 
        {
            SWorkspace->init({seq => [qw( 1 1 2 2 2)]});
            my $WSO_ra = find_reln($SWorkspace::elements[0], $SWorkspace::elements[1]);
            $WSO_ra->insert();
            return { core => $WSO_ra, direction => DIR::RIGHT() };
        }, 
    ['', 'AreTheseGroupable'],
        );



attempt_extension (
    sub 
        {
            SWorkspace->init({seq => [qw( 1 1 1 2 2 2)]});
            my $WSO_ra = find_reln($SWorkspace::elements[0], $SWorkspace::elements[1]);
            $WSO_ra->insert();
            my $WSO_ga = SAnchored->create($SWorkspace::elements[0], $SWorkspace::elements[1], );
            SWorkspace->add_group($WSO_ga);
            $WSO_ga->set_underlying_reln( $WSO_ra );
             
            return { core => $WSO_ga, direction => DIR::RIGHT() };
        }, 
    [''],
    sub {
        return SWorkspace->is_there_a_covering_group(0,2);
    });

