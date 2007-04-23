use Compile::Scripts;
[script] DescribeSolution
[param] group!
<steps>
 main::message("I will describe the solution now ($group)!", 1);
 SCRIPT DescribeInitialBlemish, { group => $group };
 ******

 SCRIPT DescribeBlocks, { group => $group };
 ******

 my $rule = $group->get_underlying_reln()->get_rule();
 SCRIPT DescribeRule, { rule => $rule };
 ******

 main::message("That finishes the description!", 1);
</steps>
no Compile::Scripts;

use Compile::Scripts;
[script] DescribeInitialBlemish
[param] group!
<steps>
    if (my $le = $group->get_left_edge()) {
        my @initial_bl = map { $_->get_mag() } @SWorkspace::elements[0..$le-1];
        main::message('There is an initial blemish in the sequence: '.
                          join(', ', @initial_bl) . ' don\'t fit', 1);
    }
    RETURN;
</steps>

no Compile::Scripts;
use Compile::Scripts;
[script] DescribeBlocks
[param] group!
<steps>
    my @parts = @$group;
    my $msg = join('; ', map { $_->get_structure_string() } @parts);
    main::message("The sequence consists of the blocks $msg", 1);
    RETURN;
</steps>

no Compile::Scripts;
use Compile::Scripts;
[script] DescribeRule
[param] rule!
<steps>
    my $state_count = $rule->get_state_count();
    if ($state_count > 1) {
        main::message("Complex rule display not implemented", 1);
        RETURN;
    } else {
        my $reln = $rule->get_relations()->[0];
        SCRIPT DescribeRelation, { reln => $reln };
    }
    *******
    RETURN;
</steps>

no Compile::Scripts;
use Compile::Scripts;
[script] DescribeRelation
[param] reln!
<steps>
    main::message("I want to describe the reln $reln", 1);
</steps>
