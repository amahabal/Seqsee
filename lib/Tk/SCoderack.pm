package Tk::SCoderack;

use Tk::widgets qw{ROText};
use base qw/Tk::Derived Tk::ROText/;

our $list;

Construct Tk::Widget 'SCoderack';

sub ClassInit{
  my ($class, $mw) = @_;
  $class->SUPER::ClassInit( $mw );
}

sub Populate{
  my ( $self, $args ) = @_;
  $list = $self;
  $self->SUPER::Populate( $args );
}

sub clear{
  $list->delete('0.0', 'end');
}

sub Update{
  $list->delete('0.0', 'end');
  my $urgencies_sum = $SCoderack::urgencies_sum;
  foreach my $fam (sort { $SCoderack::FamilyUrgency{$b} <=> $SCoderack::FamilyUrgency{$a} }
		   keys %SCoderack::FamilyUrgency) {
    my $frac = $urgencies_sum ? sprintf("%4.2f", 100 * $SCoderack::FamilyUrgency{$fam} / $urgencies_sum) : "---";
    $list->insert('end', "$frac\t$SCoderack::FamilyCount{$fam}\t$fam\n");
  }
}


1;
