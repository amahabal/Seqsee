package SBindings;
use strict;
use Carp;
use English;
use Class::Std;
use SBindings::Blemish;
use Class::Multimethods;

my %values_of_of : ATTR( :get<values_of> );
my %blemishes_of : ATTR( :get<blemishes> );

sub BUILD {
    my ( $self, $id, $opts ) = @_;
    $blemishes_of{$id} = [];
}



#### method add_blemish
# description    :marks the binding as being based on this blemish
# argument list  :$self: SBindings::Blemish $blemish
# return type    :none
# context of call:void
# exceptions     :none

sub add_blemish {
    my ( $self, $blemish ) = @_;
    UNIVERSAL::isa( $blemish, "SBindings::Blemish" )
        or croak "Need SBindings::Blemish";
    push( @{ $blemishes_of{ ident $self} }, $blemish );
}

sub set_value_of {
    my ( $self, $what_ref ) = @_;
    my $val_ref = ( $values_of_of{ ident $self} ||= {} );
    while ( my ( $k, $v ) = each %$what_ref ) {
        $val_ref->{$k} = $v;
    }
}

sub as_hash : HASHIFY {
    my ($self) = shift;
    return { %{ $values_of_of{ ident $self} } };
}

sub get_where {
    my ($self) = shift;
    return [ map { $_->get_where } @{ $blemishes_of{ ident $self} } ];
}

sub get_real {
    my ($self) = shift;
    return [ map { $_->get_real } @{ $blemishes_of{ ident $self} } ];
}

sub get_starred {
    my ($self) = shift;
    return [ map { $_->get_starred } @{ $blemishes_of{ ident $self} } ];
}

sub get_blemished {
    my ($self) = shift;
    return scalar @{ $blemishes_of{ ident $self} };
}

multimethod 'find_reln';

#### method _find_reln
# description    :finds relationship between two bindings. Intended to be private: does not return an SReln object, but just something that others may use.
# argument list  :SBlemish, SBlemish
# return type    :hashref: keys are the keys for the bindings, values are SRelns
# context of call:scalar
# exceptions     :??

multimethod _find_reln => qw(SBindings SBindings) => sub
    {
        my ($b1, $b2) = @_;
        my $ret_hash_ref;
        my @unrelated_attributes;
        my $v_hash_1 = $values_of_of{ident $b1};
        my $v_hash_2 = $values_of_of{ident $b2};
        while (my ($k, $v1) = each %$v_hash_1) {
            next unless exists $v_hash_2->{$k};
            my $v2 = $v_hash_2->{$k};
            my $reln;
            eval { $reln = find_reln($v1, $v2) };
            if ($EVAL_ERROR or not(defined $reln)) {
                push @unrelated_attributes, $k;
                print "\tthe bindings seem unrelated regarding $k\n";
                #XXX do something about this!
                next;
            }
            $ret_hash_ref->{$k} = $reln;
        }
        if (%$ret_hash_ref) {
            # aha. I have something to return!
            return $ret_hash_ref;
        } else {
            return;
        }
    };

multimethod build_right => qw(SBuiltObj HASH) =>
    sub {
        my ( $bindings, $reln_hash ) = @_;
        my $v_hash_1 = $values_of_of{ident $bindings};
        my $new_bindings_hash;
        #... should now apply relns to this, return the hash...
    };


1;
