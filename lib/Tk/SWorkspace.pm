package Tk::SWorkspace;
use strict;

use Tk::widgets qw{Canvas};
use base qw/Tk::Derived Tk::Canvas/;

Construct Tk::Widget "SWorkspace";

our ($height, $width);
our ($top_margin,  $bottom_margin);
our ($left_margin, $right_margin);
our ($eff_width, $eff_height);
our $space_per_elem;
our $space_per_group;
our %Id2Obj;
our $Canvas;
our $last_used_group_position = -1;

our @elements_options = qw{ -anchor center -fill red -activefill blue
			    -font -adobe-helvetica-bold-r-normal--20-140-100-100-p-105-iso8859-4
			 };

our @bond_options = qw{
		       -fill red -activefill blue
		       -smooth 1
		       -width  3 -activewidth 5
		     };
our @bond_options_full   = qw{ -dash 0 };
our @bond_options_partly = qw{ -dash 1 };

our @group_options = qw{-fill red -activefill blue};

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
  $Canvas = $self; # only ever a single object...
  $self->bind('wso', '<Button-1>' => 
	      sub { 
		my $objid = $Canvas->find('withtag', 'current')->[0];
		my $obj   = $Id2Obj{$objid};
		$obj->display_details;
	      });
  $self->SUPER::Populate( $args );
}

sub clear{
  $Canvas->delete('all');
  $last_used_group_position = -1;
}

sub get_new_group_pos{
  ++$last_used_group_position;
}

sub new_object{
  my $obj = shift;
  my $id = $obj->draw(@_);
  $Id2Obj{$id} = $obj;
  return $id;
}

sub GUI_add{
  my $package = shift;
  my $obj = shift;
  new_object($obj);
}

sub draw_elements{
  my $self = shift;  
  my $element_count = $SWorkspace::elements_count;
  # I want spacing so that all elements (plus 2 more) just fit...
  $eff_width  = $width - $left_margin - $right_margin;
  $eff_height = $height - $top_margin - $bottom_margin;
  $space_per_elem = $eff_width / ($element_count + 2);
  $space_per_group = ($eff_height - $top_margin - $bottom_margin) / 40;
  my $counter = 0;
  for my $elt ( @SWorkspace::elements ) {
    new_object($elt, 
	       $left_margin + (0.5 + $counter) * $space_per_elem,
	       $top_margin + $eff_height * 0.5
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

sub redraw{
  my $self = shift;
  $self->clear;
  $self->draw_elements;
}

sub SElement::draw{
  my $self = shift;
  $Canvas->createText( @_, @elements_options,
		       -text => $self->{mag}, -tags => [$self, "wso"] );
}


sub SBond::draw{
  my $self = shift;
  my ($from, $to) = ($self->{from}, $self->{to});
  my $from_bbox = $Canvas->bbox($from);
  my $to_bbox   = $Canvas->bbox($to);
  my $startx = ($from_bbox->[0] + $from_bbox->[2])/2;
  my $endx   = ($to_bbox->[0]   + $to_bbox->[2]  )/2;
  my $starty = $from_bbox->[1] - 5;
  my $endy   = $to_bbox->[1] - 5;
  my $zenith = $top_margin + $eff_height * 0.5 - ($endx - $startx);
  $zenith = $top_margin if ($zenith < $top_margin);
  my @coordinates = ($startx, $starty, 
		     $startx, $zenith,
		     $endx,   $zenith,
		     $endx,   $endy
		    );
  $Canvas->createLine(@coordinates, @bond_options, -tags => [$self, "wso"]);
}

sub SGroup::draw{
  my $self     = shift;
  my $position = get_new_group_pos();
  my $y  = $top_margin + $eff_height * 0.6 + $position * $space_per_group;
  my $ht = $space_per_group * 0.4;
  my $xstart = $left_margin + $space_per_elem * $self->{left_edge};
  my $xend   = $left_margin + $space_per_elem * ($self->{right_edge} + 1);
  #$Canvas->createLine($xstart, $y, $xend, $y, -fill => '#CCCCCC', -tags => [$self]);
  for (@{$self->{elements}}) {
    $xstart = $left_margin + $space_per_elem * $_->{left_edge};
    $xend   = $left_margin + $space_per_elem * ($_->{right_edge} + 1);
    my $id = $Canvas->createRectangle($xstart, $y - $ht,
			     $xend, $y + $ht,
			     @group_options,
			     -tags => [$self, "wso"],
			    );
    $Id2Obj{$id} = $self;
  }
}

1;
