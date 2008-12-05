package Perf::TestSequence;

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



my %String_of : ATTR(:name<string>);
my %Revealed_of : ATTR(:get<revealed>);
my %Unrevealed_of : ATTR(:get<unrevealed>);

sub START {
    my ( $self, $id, $opts_ref ) = @_;
    ( $Revealed_of{$id}, $Unrevealed_of{$id} ) =
      _NormalizeTestSequence( $self->get_string() );
}

sub IsCompatibleWith {
    my ( $self, $other ) = @_;
    my $id = ident $self;
    return unless $self->get_revealed() eq $other->get_revealed();

    my ( $unrevealed_1, $unrevealed_2 ) =
      ( $self->get_unrevealed(), $other->get_unrevealed() );
    return 1 if $unrevealed_1 =~ m#^$unrevealed_2#;
    return 1 if $unrevealed_2 =~ m#^$unrevealed_1#;
    return;
}

sub _TrimSequence {
    my ($sequence_string) = @_;
    $sequence_string =~ s#^\s*##;
    $sequence_string =~ s#\s*##;
    return join( ' ', split( /[^\d\-]+/, $sequence_string ) );
}

sub _NormalizeTestSequence {
    my ($sequence_string) = @_;
    my ( $prior, $posterior ) = split( /\|/, $sequence_string );
    return ( _TrimSequence($prior), _TrimSequence($posterior) );
}

1;
