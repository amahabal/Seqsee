package Transform::Numeric;
use 5.10.0;
use strict;
use Carp;
use Class::Std;
use Smart::Comments;

my %name_of : ATTR(:name<name>);
my %category_of : ATTR(:name<category>);

sub create {
    my ( $package, $name, $category ) = @_;
    state %MEMO;
    return $MEMO{ SLTM::encode( $name, $category ) } //= $package->new(
        {   name     => $name,
            category => $category,
        }
    );
}

sub serialize {
    my ($self) = @_;
    my $id = ident $self;
    return SLTM::encode( $name_of{$id}, $category_of{$id} );
}

sub deserialize {
    my ( $package, $str ) = @_;
    $package->create( SLTM::decode($str) );
}

sub get_memory_dependencies {
    my ($self) = @_;
    my $id = ident $self;
    return $category_of{$id};
}

sub FlippedVersion {
    my ($self) = @_;
    my $id = ident $self;
    state %FlipName = qw{same same pred succ succ pred};
    return Transform::Numeric->create( $FlipName{ $name_of{$id} }, $category_of{$id} );
}

1;
