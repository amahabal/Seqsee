#####################################################
#
#    Package: SReln::Simple
#
#####################################################
#   Package for maintianing simple relations between integers.
#####################################################

package SReln::Simple;
use strict;
use Carp;
use Class::Std;
use Class::Multimethods;
use base qw{SReln};
use Smart::Comments;
use List::Util qw(sum);

multimethod 'apply_reln_direction';

my %str_of : ATTR(:get<text>);
my %first_of : ATTR(:get<first>);      # First object in the relation. Not necessarily the left.
my %second_of : ATTR(:get<second>);    # Second object.
my %type_of : ATTR(:get<type>);        # Corresponding SRelnType::Simple object.

sub get_pure {
    my ($self) = @_;
    return $type_of{ ident $self};
}

sub BUILD {
    my ( $self, $id, $arg_ref ) = @_;
    $str_of{$id} = $arg_ref->{text} or confess "Need text!";

    $first_of{$id}  = $arg_ref->{first}  if $arg_ref->{first};
    $second_of{$id} = $arg_ref->{second} if $arg_ref->{second};
    $type_of{$id} = SRelnType::Simple->create( $arg_ref->{text} );
}

multimethod find_reln => ( '#', '#' ) => sub {
    my ( $a, $b ) = @_;
    if ( $a == $b ) {
        return SReln::Simple->new(
            {   text   => "same",
                first  => $a,
                second => $b,
            }
        );
    }
    elsif ( $a + 1 == $b ) {
        return SReln::Simple->new(
            {   text   => "succ",
                first  => $a,
                second => $b,
            }
        );
    }
    elsif ( $a - 1 == $b ) {
        return SReln::Simple->new(
            {   text   => "pred",
                first  => $a,
                second => $b,
            }
        );
    }

    return;
};

multimethod apply_reln => ( 'SReln::Simple', '#' ) => sub {
    my ( $reln, $num ) = @_;
    return apply_reln( $type_of{ ident $reln}, $num );
};

multimethod apply_reln => qw(SReln::Simple SElement) => sub {
    ## In apply_reln SReln Simple SElement
    return apply_reln( $_[0]->get_type(), $_[1] );
};

multimethod find_reln => ( '$', '$' ) => sub {
    my ( $n1, $n2 ) = @_;
    print "Should Never reach here; If it does, it means that find_reln was called with funny",
        " arguments. These, in this case, are:\n\t'$n1'\n\t'$n2'\n";
    confess "find_reln error";
};

multimethod _find_reln => qw( SElement SElement ) => sub {
    my ( $e1, $e2 ) = @_;
    my $rel = find_reln( $e1->get_mag(), $e2->get_mag );
    if ($rel) {
        my $id = ident $rel;
        $first_of{$id}  = $e1;
        $second_of{$id} = $e2;
    }
    return $rel;
};

sub as_text {
    my ($self) = @_;
    return $self->get_text;
}

multimethod are_relns_compatible => qw{SReln::Simple SReln::Simple} => sub {
    my ( $r1, $r2 ) = @_;
    return $r1->get_text() eq $r2->get_text();
};

# XXX(Board-it-up): [2007/02/03] Should the next two methods be removed?
# method: suggest_cat
# suggests a cat type based on reln
#
sub suggest_cat {
    my ($self) = @_;
    my $id     = ident $self;
    my $str    = $str_of{$id};

    if ( $str eq "same" ) {
        return $S::SAMENESS;
    }
    elsif ( $str eq "succ" ) {
        return $S::ASCENDING;
    }
    elsif ( $str eq "pred" ) {
        return $S::DESCENDING;
    }

}

sub suggest_cat_for_ends{
    my ( $self ) = @_;
    return;
}


sub as_insertlist {
    my ( $self, $verbosity ) = @_;
    my $id = ident $self;

    if ( $verbosity == 0 ) {
        return new SInsertList( $self->as_text() );
    }

    if ( $verbosity == 1 ) {
        my $list = new SInsertList;
        $list->append( $self->as_text(), "heading", "\n" );
        $list->append( "first: ", "first_second", "\n" );
        ## $list
        ## $first_of{$id}->as_insertlist(0)
        ## $first_of{$id}->as_insertlist(0)->indent(1)

        $list->concat( $first_of{$id}->as_insertlist(0)->indent(1) );

        $list->append( "Second: ", "first_second", "\n" );
        $list->concat( $second_of{$id}->as_insertlist(0)->indent(1) );
        $list->append("\n");
        return $list;
    }

    if ( $verbosity == 2 ) {
        my $list = new SInsertList;
        $list->append( $self->as_text(), "heading", "\n" );
        $list->append( "first: ", "first_second", "\n" );
        $list->concat( $first_of{$id}->as_insertlist(1)->indent(1) );

        $list->append( "Second: ", "first_second", "\n" );
        $list->concat( $second_of{$id}->as_insertlist(1)->indent(1) );
        $list->append("\n");

        $list->append( "History: ", 'heading', "\n" );
        for ( @{ $self->get_history } ) {
            $list->append("$_\n");
        }

        return $list;
    }

    confess "Verbosity $verbosity not implemented for " . ref $self;
}

sub UpdateStrength {
    my ($self) = @_;
    my $strength = 100 * SLTM::GetRealActivationsForOneConcept($self->get_type);

    $strength = 100 if $strength > 100;
    $self->set_strength($strength);
}

sub FlippedVersion {
    my ($self) = @_;
    return find_reln( reverse( $self->get_ends() ) );
}

1;

