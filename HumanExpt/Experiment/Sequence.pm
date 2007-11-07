package Experiment::Sequence;
use strict;
use Class::Std;

my %PresentedTerms_of : ATTR(:name<presented_terms>);
my %AcceptableExtensions_of : ATTR(:name<acceptable_extensions>);

{
    my %MEMO;

    sub FetchOrCreate {
        my ( $package, $opts_ref ) = @_;
        my $key = array_to_string( $opts_ref->{presented_terms} );
        if ( exists $MEMO{$key} ) {
            return $MEMO{$key};
        }
        return ( $MEMO{$key} = $package->new($opts_ref) );
    }

    sub FetchGivenPresentedTerms {
        my ( $package, $presented_ref ) = @_;
        my $key = array_to_string($presented_ref);
        return $MEMO{$key} || die "Sequence fetch attempted for unseen sequence '$key'";
    }
}

sub array_to_string {
    my ( $array_ref ) = @_;
    join(", ", @$array_ref);
}


1;
