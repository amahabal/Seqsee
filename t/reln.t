use strict;
use blib;
use Test::Seqsee;

use Class::Multimethods;
multimethod 'find_reln';

plan tests => 4; 




sub mini_copycat_test{
    my ($o1, $o2, $o3, $o4) = @_;
    $o1 = SBuiltObj->new_deep( @$o1 );
    $o2 = SBuiltObj->new_deep( @$o2 );

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
    $o3 = SBuiltObj->new_deep(@$o3);
    

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

mini_copycat_test([1, 2], [1, 2, 3], [5, 6], [5, 6, 7]);
mini_copycat_test([1, 2], [5, 6, 7]);
mini_copycat_test([1, 2], [1, 2, 3], [1, 2, 3, 2, 1]);
mini_copycat_test([1, 2, 2, 3], [1, 2, 3, 3],
                  [2, 3, 4, 4, 5, 6, 7], [2, 3, 4, 5, 5, 6, 7]
                      );
