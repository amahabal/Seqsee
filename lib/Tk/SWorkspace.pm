package Tk::SWorkspace;
use strict;

use Tk::widgets qw{Canvas};
use base qw/Tk::Derived Tk::Canvas/;

Construct Tk::Widget "SWorkspace";

our ($height, $width);
our ($top_margin,  $bottom_margin);
our ($left_margin, $right_margin);
our ($element_count);

sub ClassInit{
  my ( $class, $mw ) = @_;
  $class->SUPER::ClassInit( $mw );
}

sub Populate{
  my ($self, $args) = @_;
  $height = $args->{-height};
  $width= $args->{-width};
  $top_margin    = delete($args->{-top_margin})    || 20;
  $bottom_margin = delete($args->{-bottom_margin}) || 20;
  $left_margin   = delete($args->{-left_margin})   || 20;
  $right_margin  = delete($args->{-right_margin})  || 20;
  $self->SUPER::Populate( $args );
}

sub clear{
  shift->delete('all');
}

sub draw_elements{
  my ($self, @elements) = @_;
  my @element_mag = map { (ref $_)? $_->{magnitude} : $_ } @elements;
  $element_count = scalar(@element_mag);
  # I want spacing so that all elements (plus 2 more) just fit...
  my $eff_width  = $width - $left_margin - $right_margin;
  my $eff_height = $height - $top_margin - $bottom_margin;
  my $space_per_elem = $eff_width / ($element_count + 2);
  my $counter = 0;
  for my $elt ( @element_mag ) {
    $self->createText( $left_margin + (0.5 + $counter) * $space_per_elem,
		       $top_margin + $eff_height * 0.25,
		       -text => $elt,
		     );
    $self->createLine( $left_margin + (1 + $counter) * $space_per_elem,
		       $top_margin,
		       $left_margin + (1 + $counter) * $space_per_elem,
		       $height - $bottom_margin,
		       -fill  => '#DDDDDD',
		       -width => 1,
		     );
    $counter++;
  }
}


1;
