package SCat::OfObj::RelationTypeBased;
use 5.10.0;
use strict;
use base qw{SCat::OfObj};
use Class::Std;
use Smart::Comments;
use Class::Multimethods;
use Memoize;

multimethod 'FindTransform';
multimethod 'ApplyTransform';

my %RelationType_of : ATTR(:name<relation_type>);

sub Create {
    my ( $package, $relation_type ) = @_;
    if ( $relation_type->isa('SRelation') ) {
        $relation_type = $relation_type->get_type;
    }
    ### require: $relation_type->isa("Transform");
    state %MEMO;
    # main::message("Relation type: $relation_type: " . $relation_type->as_text);
    return ( $MEMO{$relation_type} //= $package->new( { relation_type => $relation_type,
                                                    } ) );
}


sub Instancer {
    my ( $self, $object ) = @_;
    my $id            = ident $self;
    my $relation_type = $RelationType_of{$id};

    my @parts           = @$object;
    my $parts_count     = scalar(@parts);
    my @effective_parts = map { $_->GetEffectiveObject() } @parts;

    return if $parts_count == 0;

    for my $idx ( 0 .. $parts_count - 2 ) {
        my $predicted_next = ApplyTransform($relation_type, $parts[$idx]);
        return  unless $parts[ $idx + 1 ]->CanBeSeenAs($predicted_next->get_structure);
    }

    return SBindings->new(
        {   raw_slippages => $object->GetEffectiveSlippages(),
            bindings      => { first => $parts[0], last => $parts[-1], length => SInt->new($parts_count) },
            object        => $object,
        }
    );
}

# Create an instance of the category stored in $self.
sub build {
    my ( $self, $opts_ref ) = @_;
    my $id            = ident $self;
    my $relation_type = $RelationType_of{$id};

    # xxx: only uses start and length for now.
    my $start  = $opts_ref->{first}  or return;
    my $length = $opts_ref->{length} or return;
    my $length_as_num = ref($length) ? $length->[0] : $length;
    return unless $length_as_num > 0;
    my @ret         = ($start);
    my $current_end = $start;
    for ( 1 .. $length_as_num - 1 ) {
        my $next = ApplyTransform( $relation_type, $current_end ) or return;
        push @ret, $next;
        $current_end = $next;
    }
    my $ret = SObject->create(@ret);
    $ret->add_category(
        $self,
        SBindings->new(
            {   raw_slippages => {},
                bindings      => {
                    first  => $ret->[0],
                    last   => $ret->[-1],
                    length => $length,
                },
                object => $ret
            }
        )
    );
    $ret->set_reln_scheme( RELN_SCHEME::CHAIN() );
    return $ret;
}

sub get_name {
    my ( $self ) = @_;
    my $relation_type = $RelationType_of{ident $self};
    return 'Gp based on '.$relation_type->as_text();
}
sub as_text {
    my ( $self ) = @_;
    return $self->get_name();
}

memoize('get_name');
memoize('as_text');

sub AreAttributesSufficientToBuild {
    my ( $self, @atts ) = @_;
    my $string = join(':', sort @atts);
    return 1 if ($string eq 'first:length' or $string eq 'first:last:length');
    return 0;
}

sub get_pure {
    return $_[0];    
}

sub get_memory_dependencies {
    my ( $self ) = @_;
    my $id = ident $self;
    return $RelationType_of{$id};
}

sub serialize {
    my ( $self ) = @_;
    my $id = ident $self;
    return SLTM::encode($RelationType_of{$id});
}

sub deserialize {
    my ( $package, $string ) = @_;
    my ($type) = SLTM::decode($string);
    return $package->Create($type);
}




1;
