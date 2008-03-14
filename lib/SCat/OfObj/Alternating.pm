package SCat::OfObj::Alternating;
use 5.10.0;
use strict;
use base qw{SCat::OfObj};
use Class::Std;
use Smart::Comments;
use Class::Multimethods;
use Memoize;
use Carp;

multimethod 'FindTransform';
multimethod 'ApplyTransform';

my %Object1_of : ATTR(:name<object1>);
my %Object2_of : ATTR(:name<object2>);

my $FindTransformForCat = sub  {
    my ( $me, $a, $b ) = @_;
    my $id = ident $me;

    my ($a_pure, $b_pure) = ($a->get_pure, $b->get_pure);
    my ($object1, $object2) = ($Object1_of{$id}, $Object2_of{$id});

    if ($a_pure eq $b_pure) {
        if ($a_pure eq $object1 or $a_pure eq $object2) {
            return Transform::Numeric->create($me, 'no_flip');
        } else {
            return;
        }
    } else {
        if ($a_pure eq $object1 and $b_pure eq $object2) {
            return Transform::Numeric->create($me, 'flip');
        } elsif ($a_pure eq $object2 and $b_pure eq $object1) {
            return Transform::Numeric->create($me, 'flip');
        } else {
            return;
        }
    }
};

my $ApplyTransformForCat = sub  {
    my ( $me, $transform, $object ) = @_;
    my $id = ident $me;

    my ($object_pure) = ($object->get_pure);
    my ($object1, $object2) = ($Object1_of{$id}, $Object2_of{$id});
    
    my $name = $transform->get_name();
    given ($name) {
        when ('flip') {
            if ($object_pure eq $object1) {
                return SObject->create($object2->get_structure);
            } elsif ($object_pure eq $object2) {
                return SObject->create($object1->get_structure);
            } else {
                confess "Should not be here!";
            }
        }
        when ('no_flip') {
            if ($object_pure eq $object1) {
                return SObject->create($object1->get_structure);
            } elsif ($object_pure eq $object2) {
                return SObject->create($object2->get_structure);
            } else {
                confess "Should not be here!";
            }
        }
        default { confess "Should not be here!"; }
    }
};

sub FlippingTransform {
    my ( $self ) = @_;
    return Transform::Numeric->create($self, 'flip');
}

sub Create {
    my ( $package, $o1, $o2 ) = @_;
    state %MEMO;

    my ( $pure1, $pure2 ) = sort( $o1->get_pure(), $o2->get_pure() );
    my $string = "$pure1#$pure2";
    return $MEMO{$string} //= $package->new(
        {   object1 => $pure1,
            object2 => $pure2,
            find_transform => $FindTransformForCat,
            apply_transform => $ApplyTransformForCat,
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
    my $structure_of_object;
    given ($which) {
        when ('first')  { $structure_of_object = $Object1_of{$id}->get_structure() }
        when ('second') { $structure_of_object = $Object2_of{$id}->get_structure() }
        default         { confess "Should not be here" };
    }
    my $object = SObject->create($structure_of_object);
    $object->describe_as($self);
    return $object;
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

sub CheckForAlternation {
    my ( $package, $cat, $first, $second, $third ) = @_;
    if ($first->get_pure() eq $third->get_pure()) {
        my $alternating_category = $package->Create($first->get_pure(),
                                                    $second->get_pure(),
                                                        );
        for ($first, $second, $third) {
            $_->describe_as($alternating_category);
        }
        return $alternating_category->FlippingTransform();
    }

    if (my $transform = FindTransform($first, $second)) {
        # If in this function, we know that there is no direct relation. 
        return if $transform->isa('Transform::Numeric');
    }

    my $b1 = $first->is_of_category_p($cat) or return;
    my $b2 = $second->is_of_category_p($cat) or return;
    my $b3 = $third->is_of_category_p($cat) or return;

    my ($b1, $b2, $b3) = map { $_->get_bindings_ref() } ($b1, $b2, $b3);
    my @keys = keys %$b1;
    return unless $cat->AreAttributesSufficientToBuild(@keys);

    my %changed_bindings;
    for my $key (@keys) {
        my ($v1, $v2, $v3) = ($b1->{$key}, $b2->{$key}, $b3->{$key});
        my $t1 = FindTransform($v1, $v2);
        my $t2 = FindTransform($v2, $v3);
        if ($t1 and $t1 eq $t2) {
            $changed_bindings{$key} = $t1;
        } elsif ($t1 and $t2 and $t1->get_category() eq $t2->get_category()) {
            my $new_transform = $package->CheckForAlternation($t1->get_category(),
                                                              map {$_->get_pure} ($v1, $v2, $v3)
                                                                  ) or return;
            $changed_bindings{$key} = $new_transform;
        } else {
            return;
        }
    }
    return Transform::Structural->create({
        category => $cat,
        meto_mode => $METO_MODE::NONE,
        direction_reln => $Transform::Dir::Same,
        slippages => {},
        changed_bindings => \%changed_bindings,
            });
}

1;

