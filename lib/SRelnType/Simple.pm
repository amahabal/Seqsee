#####################################################
#
#    Package: SRelnType::Simple
#
#####################################################
#####################################################

package SRelnType::Simple;
use strict;
use Carp;
use Class::Std;
use Class::Multimethods;
use base qw{SRelnType};

multimethod 'apply_reln_direction';

my %string_of : ATTR(:get<text>);
my %direction_reln_of : ATTR(:get<direction_reln>);    # Not used, for compatibility with compond

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    $string_of{$id} = $opts_ref->{string};

    # XXX(Board-it-up): [2006/11/01] Need a class Reln::Dir or some such
    $direction_reln_of{$id} = 'unknown';
}

{
    my %MEMO = ();

    sub create {
        my ( $package, $string ) = @_;
        return $MEMO{$string} ||= $package->new( { string => $string } );
    }

    sub resuscicate {
        my ( $package, $string ) = @_;
        return $MEMO{$string} ||= $package->new( { string => $string } );
    }

}

sub get_type { $_[0] }

sub as_text {
    my ($self) = @_;
    return $string_of{ ident $self};
}

sub serialize {
    my ($self) = @_;
    return $string_of{ ident $self};
}

sub deserialize {
    my ( $package, $str ) = @_;
    $package->create($str);
}

sub get_memory_dependencies {
    return;
}

multimethod apply_reln => ( 'SRelnType::Simple', '#' ) => sub {
    my ( $reln, $num ) = @_;
    my $text = $string_of{ ident $reln};

    if ( $text eq "same" ) {
        return $num;
    }
    elsif ( $text eq "succ" ) {
        return $num + 1;
    }
    elsif ( $text eq "pred" ) {
        return $num - 1;
    }
    else {
        confess "Reln not applicable to num";
    }

};

multimethod apply_reln => qw(SRelnType::Simple SElement) => sub {
    my ( $rel, $el ) = @_;
    my $new_mag = apply_reln( $rel, $el->get_mag() );

    # Need to return an selement, but unanchored. Sigh.
    my $ret = SElement->create( $new_mag, 0 );

    my $rel_dir = $rel->get_direction_reln;
    my $obj_dir = $el->get_direction;
    my $new_dir = apply_reln_direction( $rel_dir, $obj_dir );

    $ret->set_direction($new_dir);

    return $ret;
};

sub as_insertlist {
    my ( $self, $verbosity ) = @_;
    my $id = ident $self;

    return new SInsertList( $string_of{$id} );
}

1;

