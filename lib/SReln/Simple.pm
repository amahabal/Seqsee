#####################################################
#
#    Package: SReln::Simple
#
#####################################################
#   Package for maintianing simple relations between integers.
#####################################################

package SReln::Simple;
use 5.10.0;
use strict;
use Carp;
use Class::Std;
use Class::Multimethods;
use base qw{SReln};
use Smart::Comments;
use List::Util qw(sum);

multimethod 'apply_reln_direction';

my %str_of : ATTR(:get<text>);
my %first_of : ATTR(:get<first>, :set<first>)
    ;    # First object in the relation. Not necessarily the left.
my %second_of : ATTR(:get<second>, :set<second>);    # Second object.
my %type_of : ATTR(:get<type>);                      # Corresponding SRelnType::Simple object.

sub get_pure {
    my ($self) = @_;
    return $type_of{ ident $self};
}

sub BUILD {
    my ( $self, $id, $arg_ref ) = @_;
    $str_of{$id} = $arg_ref->{text} or confess "Need text!";

    $first_of{$id}  = $arg_ref->{first}  if $arg_ref->{first};
    $second_of{$id} = $arg_ref->{second} if $arg_ref->{second};
    $type_of{$id} = SRelnType::Simple->create( $arg_ref->{text},
                                               $arg_ref->{category}
                                                   );
}

multimethod find_relation_string => ( '#', '#' ) => sub {
    my ( $a, $b ) = @_;
    if ( $a == $b ) {
        return "same";
    }
    elsif ( $a + 1 == $b ) {
        return "succ";
    }
    elsif ( $a - 1 == $b ) {
        return "pred";
    }
    return;
};

multimethod apply_reln => ( 'SReln::Simple', '#' ) => sub {
    my ( $reln, $num ) = @_;
    my $cat = $reln->get_type()->get_category;
    if ($cat) {
        return $cat->ApplyRelationType($reln->get_type(), $num);
    }
    say "apply_reln(SReln::Simple #) called";
    return apply_reln( $type_of{ ident $reln}, $num );
};

multimethod apply_reln => qw(SReln::Simple SElement) => sub {
    ## In apply_reln SReln Simple SElement
    my ($self, $el) = @_;
    my $cat = $self->get_type()->get_category;
    if ($cat) {
        return $cat->ApplyRelationType($self->get_type(), $el);
    }
    say "apply_reln(SReln::Simple SElement) called";
    return apply_reln( $self->get_type(), $el );
};

multimethod apply_reln => qw(SReln::Simple SAnchored) => sub {
    return;
};

multimethod find_reln => ( '$', '$' ) => sub {
    my ( $n1, $n2 ) = @_;
    print "Should Never reach here; If it does, it means that find_reln was called with funny",
        " arguments. These, in this case, are:\n\t'$n1'\n\t'$n2'\n";
    confess "find_reln error";
};

sub as_text {
    my ($self) = @_;
    return $self->get_type()->as_text;
}

multimethod are_relns_compatible => qw{SReln::Simple SReln::Simple} => sub {
    my ( $r1, $r2 ) = @_;
    return ($r1->get_type() eq $r2->get_type());
};

# XXX(Board-it-up): [2007/02/03] Should the next two methods be removed?
# method: suggest_cat
# suggests a cat type based on reln
#
sub suggest_cat {
    my ($self) = @_;
    return $self->get_type()->suggest_cat();
}

sub suggest_cat_for_ends {
    my ($self) = @_;
    return;
}

sub UpdateStrength {
    my ($self) = @_;
    my $strength = 20 * SLTM::GetRealActivationsForOneConcept( $self->get_type );

    # Holeyness penalty
    $strength *= 0.8 if $self->get_holeyness;

    $strength = 100 if $strength > 100;
    $self->set_strength($strength);
}

sub FlippedVersion {
    my ($self) = @_;
    my $cat = $self->get_type()->get_category;
    if ($cat) {
        return find_reln( reverse( $self->get_ends() ), $cat );
    } else {
        return find_reln( reverse( $self->get_ends() ));
    }

}

1;

