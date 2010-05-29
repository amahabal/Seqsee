package SCF::LookForSimilarGroups;
use 5.010;
use MooseX::SCF;
use English qw(-no_match_vars);
use SCF;
use Class::Multimethods;

Codelet_Family(
  attributes => [group => {required => 1}],
  body => sub {
    my ($group) = @_;
    my $wset = SWorkspace::__GetObjectsBelongingToSimilarCategories($group);
    return if $wset->is_empty();

    for ( $wset->choose_a_few_nonzero(3) ) {
      SCodelet->new('FocusOn', 50, { what => $_ })->schedule();
    }

  }
);

__PACKAGE__->meta->make_immutable;

package SCF::MergeGroups;
use 5.010;
use MooseX::SCF;
use English qw(-no_match_vars);
use SCF;
use Class::Multimethods;

Codelet_Family(
  attributes => [a => {required => 1}, b => {required => 1}],
  body => sub {
    my ($a, $b) = @_;
    return if $a eq $b;
    SWorkspace::__CheckLiveness($a, $b) or return;
    my @items = SUtil::uniq(@$a, @$b);
    @items = SWorkspace::__SortLtoRByLeftEdge(@items);

    return if SWorkspace::__AreThereHolesOrOverlap(@items);
    my $new_group;
    TRY {
        my @unstarred_items = map { $_->GetUnstarred() } @items;
        ### require: SWorkspace::__CheckLivenessAtSomePoint(@unstarred_items)
        SWorkspace::__CheckLiveness(@unstarred_items) or return;    # dead objects.
        $new_group = SAnchored->create(@unstarred_items);
        if ($new_group and $a->get_underlying_reln()) {
            $new_group->set_underlying_ruleapp($a->get_underlying_reln()->get_rule());
            $a->CopyCategoriesTo($new_group);
            SWorkspace->add_group($new_group);
        }
    } CATCH {
      ConflictingGroups: { return }
    }
  }
);

__PACKAGE__->meta->make_immutable;

package SCF::CleanUpGroup;
use 5.010;
use MooseX::SCF;
use English qw(-no_match_vars);
use SCF;
use Class::Multimethods;

Codelet_Family(
  attributes => [group => {required => 1}],
  body => sub {
    my ($group) = @_;
    return unless SWorkspace::__CheckLiveness($group);
    my @edges = $group->get_edges();
    my @potential_cruft = SWorkspace::__GetObjectsWithEndsNotBeyond(@edges);
    SWorkspace::__DeleteNonSubgroupsOfFrom({ of => [$group],
                                             from => \@potential_cruft,
                                         });
  }
);

__PACKAGE__->meta->make_immutable;

