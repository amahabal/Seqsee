use strict;
use blib;
use Test::Seqsee;
plan tests => 14; 

use Smart::Comments;
use Seqsee;
use List::MoreUtils;

INITIALIZE_for_testing();

use Class::Multimethods;
multimethod 'find_reln';

Test::Stochastic::setup( times => 5);

## Test
stochastic_test_codelet (
    codefamily => 'AttemptExtension',
    setup => sub 
        {
            SWorkspace->init({seq => [qw( 1 1 1 2 2 2)]});
            my $WSO_ra = find_reln($SWorkspace::elements[0], $SWorkspace::elements[1]);
            $WSO_ra->insert();
            return { core => $WSO_ra, direction => DIR::RIGHT() };
        }, 
    throws => [''],
    post_run => sub {
        my $rel = $SWorkspace::elements[1]->get_relation($SWorkspace::elements[2]);
        return $rel;
    }

        );

## Test
stochastic_test_codelet(
    codefamily => 'AttemptExtension',
    setup => sub 
        {
            SWorkspace->init({seq => [qw( 1 1 2 2 2)]});
            my $WSO_ra = find_reln($SWorkspace::elements[0], $SWorkspace::elements[1]);
            $WSO_ra->insert();
            return { core => $WSO_ra, direction => DIR::RIGHT() };
        }, 
    throws => ['', 'AreTheseGroupable'],
        );


## Test
stochastic_test_codelet (
    codefamily => 'AttemptExtension',
    setup => sub 
        {
            SWorkspace->init({seq => [qw( 1 1 1 2 2 2)]});
            my $WSO_ra = find_reln($SWorkspace::elements[0], $SWorkspace::elements[1]);
            $WSO_ra->insert();
            my $WSO_ga = SAnchored->create($SWorkspace::elements[0], $SWorkspace::elements[1], );
            SWorkspace->add_group($WSO_ga);
            $WSO_ga->set_underlying_reln( $WSO_ra );
             
            return { core => $WSO_ga, direction => DIR::RIGHT() };
        }, 
    throws => [''],
    post_run => sub {
        return SWorkspace->is_there_a_covering_group(0,2);
    });

## Test
stochastic_test_codelet (
    codefamily => 'AttemptExtension',
    setup => sub 
        {
            SWorkspace->init({seq => [qw( 1 1 1 2 2 2)]});
            my $WSO_ra = find_reln($SWorkspace::elements[2], $SWorkspace::elements[1]);
            $WSO_ra->insert();
            return { core => $WSO_ra, direction => DIR::LEFT() };
        }, 
    throws => [''],
    post_run => sub {
        my $rel = $SWorkspace::elements[1]->get_relation($SWorkspace::elements[0]);
        return $rel;
    }

        );

## Test
stochastic_test_codelet (
    codefamily => 'AttemptExtension',
    setup => sub 
        {
            SWorkspace->init({seq => [qw( 1 1 1 2 2 2)]});
            my $WSO_ra = find_reln($SWorkspace::elements[2], $SWorkspace::elements[1]);
            $WSO_ra->insert();
            my $WSO_ga = SAnchored->create($SWorkspace::elements[2], $SWorkspace::elements[1], );
            SWorkspace->add_group($WSO_ga);
            $WSO_ga->set_underlying_reln( $WSO_ra );
             
            return { core => $WSO_ga, direction => DIR::LEFT() };
        }, 
    throws => [''],
    post_run => sub {
        return SWorkspace->is_there_a_covering_group(0,2);
    });

## Test
stochastic_test_codelet (
    codefamily => 'AttemptExtension',
    setup => sub 
        {
            SWorkspace->init({seq => [qw( 1 1 1 2 2 2)]});
            my $WSO_ra = find_reln($SWorkspace::elements[1], $SWorkspace::elements[0]);
            $WSO_ra->insert();
            my $WSO_ga = SAnchored->create($SWorkspace::elements[1], $SWorkspace::elements[0], );
            SWorkspace->add_group($WSO_ga);
            $WSO_ga->set_underlying_reln( $WSO_ra );
             
            return { core => $WSO_ga, direction => DIR::RIGHT() };
        }, 
    throws => [''],
    post_run => sub {
        return SWorkspace->is_there_a_covering_group(0,2);
    });

## Test
stochastic_test_codelet (
    codefamily => 'AttemptExtension',
    setup => sub 
        {
            SWorkspace->init({seq => [qw( 1 1 1 2 2 2)]});
            my $WSO_ra = find_reln($SWorkspace::elements[1], $SWorkspace::elements[0]);
            $WSO_ra->insert();
            return { core => $WSO_ra, direction => DIR::RIGHT() };
        }, 
    throws => [''],
    post_run => sub {
        my $rel = $SWorkspace::elements[1]->get_relation($SWorkspace::elements[2]);
        return $rel;
    }

        );
