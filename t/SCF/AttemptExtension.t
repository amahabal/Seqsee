use strict;
use blib;
use Test::Seqsee;
plan tests => 20; 

use Smart::Comments;
use Seqsee;


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
            SWorkspace->init({seq => [qw( 1 1 2 2 2 3 3 3 3)]});
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
            SWorkspace->init({seq => [qw( 1 1 1 2 2 2 3 3 3 )]});
            my $WSO_ra = find_reln($SWorkspace::elements[0], $SWorkspace::elements[1]);
            $WSO_ra->insert();
            my $WSO_ga = SAnchored->create($SWorkspace::elements[0], $SWorkspace::elements[1], );
            SWorkspace->add_group($WSO_ga);
            $WSO_ga->set_underlying_reln( $WSO_ra );
             
            return { core => $WSO_ga, direction => DIR::RIGHT() };
        }, 
    throws => ['', 'AreWeDone'],
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

### Test
stochastic_test_codelet (
    codefamily => 'AttemptExtension',
    setup => sub 
        {
            SWorkspace->init({seq => [qw( 1 1 1 2 2 2 3 3 3 4 4 4 5 5 5)]});
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

### Test
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

stochastic_test_codelet( 
    codefamily => 'AttemptExtension', 
    setup      => sub {
        SWorkspace->init({seq => [qw( 0 0 1 1 2 2 3 3)]});
        my $WSO_ga = SAnchored->create($SWorkspace::elements[2], $SWorkspace::elements[3], );
        SWorkspace->add_group($WSO_ga);
        $WSO_ga->describe_as($S::SAMENESS);

        my $WSO_gb = SAnchored->create($SWorkspace::elements[4], $SWorkspace::elements[5], );
        SWorkspace->add_group($WSO_gb);
        $WSO_gb->describe_as($S::SAMENESS);
        
        my $WSO_ra = find_reln($WSO_ga, $WSO_gb);
        $WSO_ra->insert();
         
        return { core => $WSO_ra, direction => DIR::RIGHT() };

        },
    throws     => [ '' ],
    post_run   => sub {
        my $gp = SWorkspace->is_there_a_covering_group(6,7);
        
        my $WSO_rd = $SWorkspace::elements[6]->get_relation($SWorkspace::elements[7]);
        ## $WSO_rd, $gp
        return ($WSO_rd and $gp and $gp->instance_of_cat($S::SAMENESS));
        }
        );


stochastic_test_codelet (
    codefamily => 'AttemptExtension',
    setup => sub 
        {
            SWorkspace->init({seq => [qw( 1 1 1 2 2 2 3 3)]});
            SWorkspace->set_future_terms(3);
            my $WSO_ga = SAnchored->create($SWorkspace::elements[0], $SWorkspace::elements[1], $SWorkspace::elements[2], );
            SWorkspace->add_group($WSO_ga);
            $WSO_ga->describe_as($S::SAMENESS);

            my $WSO_gb = SAnchored->create($SWorkspace::elements[3], $SWorkspace::elements[4], $SWorkspace::elements[5], );
            SWorkspace->add_group($WSO_gb);
            $WSO_gb->describe_as($S::SAMENESS);

            my $WSO_ra = find_reln($WSO_ga, $WSO_gb);
            $WSO_ra->insert();
             
            return { core => $WSO_ra, direction => DIR::RIGHT() };
        }, 
    throws => [''],
    post_run => sub {
        return ($SWorkspace::elements_count == 9) ? 1 : 0;
    }

        );

stochastic_test_codelet (
    codefamily => 'AttemptExtension',
    setup => sub 
        {
            SWorkspace->init({seq => [qw( 1 1 2 3 1 2 2 3 1 2 3 3)]});
            my $WSO_ga = SAnchored->create($SWorkspace::elements[0], $SWorkspace::elements[1], );
            SWorkspace->add_group($WSO_ga);
            $WSO_ga->describe_as( $S::SAMENESS);
            $WSO_ga->annotate_with_metonym( $S::SAMENESS, "each");
            $WSO_ga->set_metonym_activeness(1);

            my $WSO_gb = SAnchored->create($SWorkspace::elements[5], $SWorkspace::elements[6], );
            SWorkspace->add_group($WSO_gb);
            $WSO_gb->describe_as( $S::SAMENESS);
            $WSO_gb->annotate_with_metonym( $S::SAMENESS, "each");
            $WSO_gb->set_metonym_activeness(1);
 
            my $WSO_gc = SAnchored->create($WSO_ga, $SWorkspace::elements[2], $SWorkspace::elements[3], );
            SWorkspace->add_group($WSO_gc);
            $WSO_gc->describe_as($S::ASCENDING);
            $WSO_gc->tell_forward_story($S::ASCENDING);

            my $WSO_gd = SAnchored->create($SWorkspace::elements[4], $WSO_gb, $SWorkspace::elements[7], );
            SWorkspace->add_group($WSO_gd);
            $WSO_gd->describe_as($S::ASCENDING);
            $WSO_gd->tell_forward_story($S::ASCENDING);
            
            my $WSO_ra = find_reln($WSO_gc, $WSO_gd);
            ## $WSO_ra
            $WSO_ra->insert();
             
            return { core => $WSO_ra, direction => DIR::RIGHT() };
        }, 
    throws => [''],
    post_run => sub {
        return ($SWorkspace::elements_count == 12) ? 1 : 0;
    }

        );
