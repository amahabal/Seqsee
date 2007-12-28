package SCat::OfObj::Interlaced;
use strict;
use base qw{SCat::OfObj};
use Class::Std;
use Smart::Comments;
use Class::Multimethods;
use Memoize;

my %PartsCount_of : ATTR(:name<parts_count>);

{
    my %MEMO;

    sub Create {
        my ( $package, $parts_count ) = @_;
        return ( $MEMO{$parts_count} ||= $package->new( { parts_count => $parts_count } ) );
    }
}

sub Instancer {
    my ( $self, $object ) = @_;
    my $id          = ident $self;
    my $parts_count = $PartsCount_of{$id};

    my $parts_ref = $object->get_parts_ref;
    return unless scalar(@$parts_ref) == $parts_count;

    my %bdgs = ();
    for my $i ( 1 .. $parts_count ) {
        $bdgs{"part_no_$i"} = $parts_ref->[ $i - 1 ];
    }
    return SBindings->create( {}, \%bdgs, $object );
}

# Create an instance of the category stored in $self.
sub build {
    my ( $self, $opts_ref ) = @_;
    my $id = ident $self;
    my $parts_count = $PartsCount_of{$id};

    my @ret_parts;

    for my $i ( 1 .. $parts_count ) {
        push @ret_parts, $opts_ref->{"part_no_$i"};
    }

    return SObject->create(@ret_parts);
}

sub get_name {
    my ($self) = @_;
    my $id          = ident $self;
    my $parts_count = $PartsCount_of{$id};
    return "Interlaced_$parts_count";
}

sub as_text {
    my ($self) = @_;
    return $self->get_name();
}

memoize('get_name');
memoize('as_text');

sub get_pure {
    return $_[0];
}

sub get_memory_dependencies {
    my ($self) = @_;
    my $id = ident $self;
    return;
}

sub serialize {
    my ($self) = @_;
    my $id = ident $self;
    return $PartsCount_of{$id};
}

sub deserialize {
    my ( $package, $string ) = @_;
    $package->Create($string);
}

sub AreAttributesSufficientToBuild {
    my ( $self, @atts ) = @_;
    return 1 if scalar(grep {/^part_no_/} (SUtil::uniq(@atts))) == $PartsCount_of{ident $self};
    return;
}
1;
