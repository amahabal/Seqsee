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

use Class::Multimethods;
multimethod 'find_relation_string';
multimethod 'find_reln';
multimethod find_relation_type => ('#', '#') => sub  {
    my ( $a, $b ) = @_;
    my $string = find_relation_string($a, $b) or return;
    return SRelnType::Simple->create($string);
};

multimethod find_relation_type => ('SElement', 'SElement') => sub  {
    my ( $a, $b ) = @_;
    my $string = find_relation_string($a->get_mag(), $b->get_mag()) or return;
    return SRelnType::Simple->create($string);
};

multimethod find_relation_type => ('SAnchored', 'SAnchored') => sub  {
   my ( $a, $b ) = @_;
   my $reln = find_reln($a, $b) or return;
   return $reln->get_type;
};

1;
