#####################################################
#
#    Package: SReln::Dir
#
#####################################################
#####################################################

package SReln::Dir;
use strict;
use warnings;
use Carp;
use Class::Std;
use base qw{};
use Class::Multimethods;

my %string_of : ATTR();

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    $string_of{$id} = $opts_ref->{string};
}

{
    my %MEMO = ();

    sub create {
        my ( $package, $string ) = @_;
        return $MEMO{$string} ||= $package->new( { string => $string } );
    }
}

our $Same      = SReln::Dir->create('Same');
our $Different = SReln::Dir->create('Different');
our $Unknown   = SReln::Dir->create('Unknown');

multimethod find_reln => qw(DIR DIR) => sub {
    my ( $da, $db ) = @_;
    if ( $da eq DIR::RIGHT() ) {
        return ( $db eq DIR::RIGHT() ) ? $Same
            : ( $db  eq DIR::LEFT() )  ? $Different
            :                            $Unknown;
    }
    elsif ( $da eq DIR::LEFT() ) {
        return ( $db eq DIR::RIGHT() ) ? $Different
            : ( $db  eq DIR::LEFT() )  ? $Same
            :                            $Unknown;
    }
    else {
        return $Unknown;
    }
};

multimethod apply_reln => qw(SReln::Dir DIR) => sub {
    my ( $rel_dir, $dir ) = @_;
    if ( $rel_dir eq $Unknown ) {
        return DIR::UNKNOWN();
    }
    if ( $rel_dir eq $Same ) {
        return $dir;
    }
    if ( $rel_dir eq $Different ) {
        return ( $dir eq DIR::RIGHT() ) ? DIR::LEFT()
            : ( $dir  eq DIR::LEFT() )  ? DIR::RIGHT()
            :                             DIR::UNKNOWN();
    }
};

sub get_memory_dependencies { return; }

sub serialize {
    my ($self) = @_;
    return $string_of{ident $self};
}

sub deserialize {
    my ( $package, $str ) = @_;
    no strict 'refs';
    return ${$str};
}

sub as_text {
    my ($self) = @_;
    return "Dir " . $string_of{ident $self};
}

1;

