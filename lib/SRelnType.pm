#####################################################
#
#    Package: SRelnType
#
#####################################################
#####################################################

package SRelnType;
use strict;
use Carp;
use Class::Std;
use base qw{};

sub get_pure {
  return $_[0];
}

# use Class::Multimethods;
# multimethod 'find_relation_string';
# multimethod 'find_reln';
# multimethod find_relation_type => ('#', '#') => sub  {
#     my ( $a, $b ) = @_;
#     my $string = find_relation_string($a, $b) or return;
#     return SRelnType::Simple->create($string);
# };

# multimethod '_find_reln';
# multimethod find_relation_type => ('SElement', 'SElement') => sub  {
#     my ( $a, $b ) = @_;
#     if (my $rel = $a->get_relation($b)) {
#         return $rel->get_type;
#     }
#     my $rel = _find_reln($a, $b) or return;
#     return $rel->get_type();
# };

# multimethod find_relation_type => ('#', 'SElement') => sub  {
#     my ( $a, $b ) = @_;
#     return find_relation_type($a, $b->get_mag());
# };

# multimethod find_relation_type => ('SElement', '#') => sub  {
#     my ( $a, $b ) = @_;
#     return find_relation_type($a->get_mag(), $b);
# };

# multimethod find_relation_type => ('SAnchored', '#') => sub  {
#     my ( $obj, $n ) = @_;
#     my $effective_object = $obj->GetEffectiveObject;
#     return if $obj eq $effective_object;
#     return find_relation_type($effective_object, $n);
# };

# multimethod find_relation_type => ('#', 'SAnchored') => sub  {
#     my ( $n, $obj ) = @_;
#     my $effective_object = $obj->GetEffectiveObject;
#     return if $obj eq $effective_object;
#     return find_relation_type($n, $effective_object);
# };

# multimethod find_relation_type => ('SAnchored', 'SAnchored') => sub  {
#    my ( $a, $b ) = @_;
#    my $reln = find_reln($a, $b) or return;
#    return $reln->get_type;
# };

# multimethod find_relation_type => ('SInt', 'SInt') => sub  {
#     my ( $a, $b ) = @_;
#     use 5.10.0;
#     say "find_relation_type: ", $a, ' and ', $b;
#     my $cat = SLTM::SpikeAndChoose(0, $a->get_common_categories($b)) or return;
#     say "cat: $cat";
#     my $rel =  $cat->FindRelationBetween($a->[0], $b->[0]) or return;
#     say "rel: $rel";
#     return $rel->get_type;
# };

1;
