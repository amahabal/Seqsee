use Compile::SThought;
[package] SThought::LargeGroup
[param] group!

<fringe>
</fringe>
<actions>
my $flush_right = $group->IsFlushRight();
my $flush_left = $group->IsFlushLeft();

if ($flush_right and $flush_left) {
    THOUGHT AreWeDone, { group => $group};
} elsif ($flush_right and !$flush_left) {
    THOUGHT MaybeStartBlemish, {group => $group};
} 

</actions>

no Compile::SThought;

use Compile::SThought;
[package] SThought::MaybeStartBlemish
[param] group!
<fringe>

</fringe>
<actions>
my $flush_right = $group->IsFlushRight();
my $flush_left = $group->IsFlushLeft();
if (!$flush_left) {
    my $extension = $group->FindExtension($DIR::LEFT, 0);
    if ($extension) {
    } else {
        # So there *is* a blemish!
        #main::message("Start Blemish?");
        my $underlying_rule = $group->get_underlying_reln()->get_rule();
        my $statecount = $underlying_rule->get_state_count();
        if ($statecount == 1) {
            my $reln = $underlying_rule->get_relations()->[0];
            #main::message("Blemish reln: $reln");
            if ($reln->isa("SRelnType::Compound")) {
                my $cat = $reln->get_base_category();
                #main::message($cat->get_name());
                if ($cat->get_name() =~ m#^ad_hoc_(.*)#o) {
                    THOUGHT InterlacedInitialBlemish, { count => $1,
                                                        group => $group,
                                                        cat => $cat,
                                                    };
                    return;
                }
            }
        }
        # So: either statecount > 1, or not interlaced.
        THOUGHT ArbitraryInitialBlemish, { group => $group};
    }
}    
</actions>

no Compile::SThought;
use Compile::SThought;
[package] SThought::InterlacedInitialBlemish
[param] count!
[param] group!
[param] cat!
<fringe> 
</fringe>
<actions>
    main::message("I realize that there are $count interlaced groups in the sequence, and I have started on the wrong foot. Will shift the big group right one unit, see if that helps!!");
    my @parts = @$group;
    my @subparts = map { @$_ } @parts;
    SWorkspace->remove_gp($group);
    SWorkspace->remove_gp($_) for @parts;
    shift(@subparts);
my @newparts;
while (@subparts > $count) {
    my @new_part;
    for (1..$count) {
        push @new_part, shift(@subparts);
    }
    my $newpart = SAnchored->create(@new_part);
    $newpart->describe_as($cat);
    SWorkspace->add_group($newpart);
    push @newparts, $newpart;
}
 my $new_gp =  SAnchored->create(@newparts);
 SWorkspace->add_group($new_gp);
 SThought->create($new_gp)->schedule();
</actions>

no Compile::SThought;
use Compile::SThought;
[package] SThought::ArbitraryInitialBlemish
[param] group!
<fringe>
</fringe>
<actions>
    my $left_edge = $group->get_left_edge();
    my $msg = "There seems to be a strange blemish at the start! The initial ";
$msg .= join(", ", map { $_->get_mag()} @SWorkspace::elements[0..$left_edge-1])
    ;
    $msg .= ' does not seem to fit in!';
   main::message($msg);
</actions>
