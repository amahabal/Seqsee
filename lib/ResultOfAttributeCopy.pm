package ResultOfAttributeCopy;
use strict;

use Class::Std;
my %status_of : ATTR(:name<status>);

my $FAILED  = ResultOfAttributeCopy->new( { status => 'failed' } );
my $SUCCESS = ResultOfAttributeCopy->new( { status => 'succeeded' } );

sub FAILED {
    return ResultOfAttributeCopy->new( { status => 'failed' } );
}

sub SUCCESS {
    return ResultOfAttributeCopy->new( { status => 'succeeded' } );
}

sub WasSuccessful {
    my ($self) = @_;
    my $id = ident $self;
    return ( $status_of{$id} eq 'succeeded' ) ? 1 : 0;
}

sub UpdateWith {
    my ( $self, $new_value ) = @_;
    my $id = ident $self;
    $status_of{$id} = 'failed' if ( !$new_value->WasSuccessful() );
}

1;
