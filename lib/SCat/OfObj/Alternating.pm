package SCat::OfObj::Alternating;
use 5.10.0;
use strict;
use base qw{SCat::OfObj};
use Class::Std;
use Smart::Comments;
use Class::Multimethods;
use Memoize;

multimethod 'FindTransform';
multimethod 'ApplyTransform';

my %Object1_of : ATTR(:name<object1>);
my %Object2_of : ATTR(:name<object2>);

sub Create {
    my ( $package, $o1, $o2 ) = @_;
    state %MEMO;

    my ( $pure1, $pure2 ) = sort( $o1->get_pure(), $o2->get_pure() );
    my $string = "$pure1#$pure2";
    return $MEMO{$string} //= $package->new(
        {   object1 => $pure1,
            object2 => $pure2,
        }
    );
}

sub Instancer {
    my ( $self, $object ) = @_;
    my $id   = ident $self;
    my $pure = $object->get_pure();
    my $which;
    if ( $pure eq $Object1_of{$id} ) {
        $which = 'first';
    }
    elsif ( $pure eq $Object2_of{$id} ) {
        $which = 'second';
    }
    else {
        return;
    }

    return SBindings->new(
        {   raw_slippages => {},
            bindings      => { which => $which },
            object        => $object,
        }
    );
}

sub build {
    my ( $self, $opts_ref ) = @_;
    my $id = ident $self;
    my $which = $opts_ref->{which} or confess "need which";
    given ($which) {
        when ('first')  { return $Object1_of{$id} }
        when ('second') { return $Object2_of{$id} }
        default         { confess "Should not be here" };
    }
}

sub get_name {
    my ($self) = @_;
    my $id = ident $self;
    return 'Alternate between '
        . $Object1_of{$id}->as_text() . ' and '
        . $Object2_of{$id}->as_text();
}

sub as_text {
    my ( $self ) = @_;
    return $self->get_name();
}

memoize('get_name');
memoize('as_text');

sub AreAttributesSufficientToBuild {
    my ( $self, @atts ) = @_;
    return 1 if 'which' ~~ @atts;
    return;
}

sub get_pure {
    return $_[0];
}

sub get_memory_dependencies {
    my ( $self ) = @_;
    my $id = ident $self;
    return ($Object1_of{$id}, $Object2_of{$id});
}

sub serialize {
    my ( $self ) = @_;
    my $id = ident $self;
    return SLTM::encode($Object1_of{$id}, $Object2_of{$id});
}

sub deserialize {
    my ( $package, $string ) = @_;
    my ($o1, $o2) = SLTM::decode($string);
    return $package->Create($o1, $o2);
}

1;

