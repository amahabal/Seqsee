package Tk::SCoderack;

use Tk::widgets qw{MListbox};
use base qw/Tk::Derived Tk::MListbox/;

our $list;
our @columns = ( [-text => "Family",
		 ],
		 [-text => "# codelets", 
		 ],
		 [-text => '% Urgency', 
		 ],
	       );

Construct Tk::Widget 'SCoderack';

sub ClassInit{
  my ($class, $mw) = @_;
  $class->SUPER::ClassInit( $mw );
}

sub Populate{
  my ( $self, $args ) = @_;
  $list = $self;
  $args->{-moveable} = 0;
  $args->{-columns}  = \@columns;
  $self->SUPER::Populate( $args );
}

sub clear{
  $list->delete(0, 'end');
}

sub update{
  $list->delete(0, 'end');
  my $urgencies_sum = $SCoderack::urgencies_sum;
  foreach my $fam (keys %SCoderack::FamilyCount) {
    my $frac = $urgencies_sum ? sprintf("%4.2f", 100 * $SCoderack::FamilyUrgency{$fam} / $urgencies_sum) : "---";
    $list->insert('end', [$fam, 
			  $SCoderack::FamilyCount{$fam},
			  $frac]
		 );
  }
}


1;
