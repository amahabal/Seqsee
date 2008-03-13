package SCat::OfObj::Literal;
use strict;
use base qw{SCat::OfObj};
use Class::Std;
use Smart::Comments;
use Class::Multimethods;
use Memoize;
use Carp;

my %String_of : ATTR(:name<string>);
my %Prototype_of : ATTR(:name<prototype>);

{
    my %MEMO;

    sub Create {
        my ( $package, $structure ) = @_;

        my $prototype = SObject->create($structure);
        my $string    = scat_literal_as_string( $prototype->get_structure );
        return (
            $MEMO{$string} ||= $package->new(
                {   string    => $string,
                    prototype => $prototype,
                }
            )
        );
    }
}

sub Instancer {
    my ( $self, $object ) = @_;
    my $id                       = ident $self;
    my $prototype                = $Prototype_of{$id};
    my $result_of_can_be_seen_as = $object->CanBeSeenAs($prototype) or return;
    my $slippages                = $result_of_can_be_seen_as->GetPartsBlemished() || {};

    # Special case: $object is a SElement
    if ( $object->isa('SElement') ) {
        if ( my $entire_blemish = $result_of_can_be_seen_as->GetEntireBlemish() ) {
            $slippages = { 0 => $entire_blemish };
        }
    }
    ## $slippages

    return SBindings->create( $slippages, {}, $object );
}

sub build {
    my ( $self, $opts_ref ) = @_;
    return SObject->create( $Prototype_of{ ident $self} );
}

sub get_name {
    my ($self) = @_;
    return "Literal " . $String_of{ ident $self};
}

sub as_text {
    my ($self) = @_;
    return "Literal " . $String_of{ ident $self};
}
memoize('get_name');
memoize('as_text');

sub get_pure {
    return $_[0];
}

sub get_memory_dependencies {
    my ($self) = @_;
    return;
}

sub serialize {
    my ($self) = @_;
    my $id = ident $self;
    return $String_of{$id};
}

sub deserialize {
    my ( $package, $string ) = @_;
    return $package->Create($string);
}

sub scat_literal_as_string {
    my $structure = shift;
    if ( ref $structure ) {
        return "[ " . join( ", ", map { scat_literal_as_string($_) } @$structure ) . " ]";
    }
    else {
        return $structure;
    }
}

sub AreAttributesSufficientToBuild {
    1;
}


1;
