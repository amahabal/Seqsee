use Compile::SCF;
[package] SCF::DescribeSolution
[param] group!
[param] state
<run>
    $state = 0 unless defined($state);
if ($state == 0) {
    main::message("I will describe the solution now $group!", 1);
    SCodelet->new('DescribeInitialBlemish', 10000, {group => $group})->schedule();
} elsif ($state == 1) {
    SCodelet->new('DescribeBlocks', 10000, { group => $group })->schedule();
} elsif ($state == 2) {
    my $rule = $group->get_underlying_reln()->get_rule();
    SCodelet->new('DescribeRule', 10000, { group => $group, rule => $rule})->schedule();
} else {
    main::message("Unknown state '$state'");
}
</run>

no Compile::SCF;
use Compile::SCF;
[package] SCF::DescribeInitialBlemish
[param] group!
<run>
    if (my $le = $group->get_left_edge()) {
        my @initial_bl = map { $_->get_mag() } @SWorkspace::elements[0..$le-1];
        main::message('There is an initial blemish in the sequence: '.
                          join(', ', @initial_bl) . ' don\'t fit', 1);
    }
    SCodelet->new('DescribeSolution', 10000, {group => $group, state => 1})->schedule();
</run>

no Compile::SCF;
use Compile::SCF;
[package] SCF::DescribeBlocks
[param] group!
[param] state
<run>
    $state = 0 unless defined($state);
if ($state == 0) {
    my @parts = @$group;
    my $msg = join('; ', map { $_->get_structure_string() } @parts);
    main::message("The sequence consists of the blocks $msg", 1);
} else {
    main::message("hmmmm");
}
    SCodelet->new('DescribeSolution', 10000, {group => $group, state => 2})->schedule();
    
</run>
no Compile::SCF;
use Compile::SCF;
[package] SCF::DescribeRule
[param] rule!
[param] group!
[param] state
<run>
    $state = 0 unless defined($state);
if ($state == 0) {
    my $state_count = $rule->get_state_count();
    if ($state_count > 1) {
        main::message("Complex rule display not implemented", 1);
        SCodelet->new('DescribeSolution', 10000, {group => $group, state => 3})->schedule();
    } else {
        my $reln = $rule->get_relations()->[0];
        SCodelet->new('DescribeRelation', 10000, {group => $group,
                                              rule => $rule,
                                              reln => $reln,
                                                     })->schedule();
    }
} else {
    SCodelet->new('DescribeSolution', 10000, {group => $group, state => 3})->schedule();    
}

</run>

no Compile::SCF;
use Compile::SCF;
[package] SCF::DescribeRelation
[param] rule!
[param] group!
[param] reln!
[param] state
<run>
    $state = 0 unless defined($state);
main::message("I want to describe the reln $reln", 1);
SCodelet->new('DescribeRule', 10000, { rule => $rule, group => $group, state => 2})->schedule();
</run>
