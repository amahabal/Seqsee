use strict;
use blib;
use Test::Seqsee;
use Smart::Comments;

use Class::Multimethods;
multimethod 'find_reln';
multimethod 'sequal_strict';

plan tests => 7; 





#### method mini_copycat_test
# description    :assuming inputs are array_refs intended to be SBuiltObjs, finds the relation between the first two, applies it to the third, and checks that what is obtained is equal to the fourth.
# argument list  :the four array refs, the third and fourth of which may be undef
# return type    :none. Calls ok(0) or ok(1) appropriately
# context of call:void
# exceptions     :

sub mini_copycat_test{
    my ($o1, $o2, $o3, $o4) = @_;
    $o1 = SBuiltObj->new_deep( @$o1 );
    $o1->seek_categories( $S::cats_and_blemish_ref );
    $o2 = SBuiltObj->new_deep( @$o2 );
    $o2->seek_categories( $S::cats_and_blemish_ref );

    my $reln;
    if (not defined $o3) {
        # expect failure!
        eval { $reln = find_reln($o1, $o2) };
        if ($EVAL_ERROR or not(defined $reln)) {
            # aha! failed, as expected
            ok(1, "Expected failure");
            return;
        } else {
            # didn't fail!
            ok(0, "should have encountered an error--didn't: $EVAL_ERROR");
            return;
        }
    } 
    # So: no error expected

    eval { $reln = find_reln($o1, $o2) };
    if ($EVAL_ERROR) {
        ok(0, "a relation should have been found! $EVAL_ERROR");
        return;
    } 
    ### $reln
    $o3 = SBuiltObj->new_deep(@$o3);
    $o3->seek_categories( $S::cats_and_blemish_ref );
    

    # We'll now "apply" the relation. 
    my $built_o4;
    if (not defined $o4) {
        # expect failure
        eval { $built_o4 = $reln->build_right($o3) };
        if ($EVAL_ERROR or not(defined $built_o4)) {
            # good, failed as expected
            ok(1, "expected: reln could not be applied");
        } else {
            ok(0, "unexpected: reln should not be applicable; $EVAL_ERROR");
        }
        return;
    }
    my $o4 = SBuiltObj->new_deep(@$o4);
    # categories of o4 irrelevant, so won't seek them
    eval { $built_o4 = $reln->build_right($o3) };
    if ($EVAL_ERROR or not(defined $built_o4)) {    
        ok(0, "Unexpected: error in applying relation. $EVAL_ERROR");
    } elsif (sequal_strict($o4, $built_o4)) {
        ok(1, "equal as expected");
    } else {
        ok(0, "relation was applied, but wrong result! $EVAL_ERROR");
    }
    return;
}

my $succ = find_reln(3, 4);
my $seven = $succ->build_right(6);
cmp_ok($seven, '==', 7);
ok( sequal_strict( 7, $seven ));

my $five = $succ->build_left(6);
cmp_ok($five, '==', 5);

mini_copycat_test([1, 2], [1, 2, 3], [5, 6], [5, 6, 7]);
exit;
mini_copycat_test([1, 2], [5, 6, 7]);
mini_copycat_test([1, 2], [1, 2, 3], [1, 2, 3, 2, 1]);
mini_copycat_test([1, 2, 2, 3], [1, 2, 3, 3],
                  [2, 3, 4, 4, 5, 6, 7], [2, 3, 4, 5, 5, 6, 7]
                      );
