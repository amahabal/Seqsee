package Perf::Version;
use 5.10.0;

## STANDARD MODULES THAT I INCLUDE EVERYWHERE
use strict;
use warnings;

use List::Util qw{min max sum first};
use Time::HiRes;
use Getopt::Long;
use Storable;

use File::Slurp;
use Smart::Comments;
use IO::Prompt;
use Class::Std;
use Class::Multimethods;

use Carp;
## END OF STANDARD INCLUDES



my %Major_of : ATTR(:name<major>);
my %Minor_of : ATTR(:name<minor>);

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    my $string = $opts_ref->{string};
    $string =~ s#\s##g;

    if ($string eq 'human') {
        $Major_of{$id} = $Minor_of{$id} = '';
        return;
    }

    ( $Major_of{$id}, $Minor_of{$id} ) = split( /:/, $string );
    confess "Strange version '$string'" unless defined($Minor_of{$id});

}

sub _cmp {
    my ( $a, $b ) = @_;
    my ( $a1, $a2, $b1, $b2 ) =
      map { ( $_->get_major(), $_->get_minor() ) } ( $a, $b );
    return $a1 <=> $b1 || $a2 <=> $b2;
}

use overload '<=>' => \&_cmp;

1;

