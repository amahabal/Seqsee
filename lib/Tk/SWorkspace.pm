package Tk::SWorkspace;
use strict;
use Config::Std;
use Smart::Comments;
use Tk::widgets qw{Canvas};
use List::Util qw(min max);
use List::MoreUtils qw(minmax);
use base qw/Tk::Derived Tk::Canvas/;

our $canvas;
our %Id2Obj;
my ($Height, $Width, $Margin);
my ($eff_width, $eff_height);
my ($group_space_offset, $group_spacing_factor, $group_row_count, $group_space_height);
my ($group_row_size, $eff_group_row_size);
my (@element_options, @line_options, @reln_bgd_options, @reln_fgd_options,
    @group_bgd_options, @group_fgd_options
        );
my ($space_per_elem);
my @used_spots;

BEGIN {
    read_config 'config/GUI_ws.conf' => my %config;
    @element_options  = %{$config{elements}};
    @line_options     = %{$config{line}};
    @reln_bgd_options = %{$config{reln_bgd}}; 
    @reln_fgd_options = %{$config{reln_fgd}}; 
    @group_bgd_options = %{$config{group_bgd}}; 
    @group_fgd_options = %{$config{group_fgd}}; 
    $Margin            = $config{placing}{-margin};
    $group_spacing_factor = $config{placing}{-group_spacing_factor};
    $group_row_count      = $config{placing}{-group_row_count};
}

Construct Tk::Widget 'SWorkspace';

sub Populate{
    my ( $self, $args ) = @_;
    my $element_choices = delete $args->{-element_choices};
    $canvas = $self;
    $Height = $canvas->cget('height');
    $Width  = $canvas->cget('width');

    $eff_width  = $Width - 2 * $Margin;
    $eff_height = $Height - 2 * $Margin;
    $group_space_offset = $Margin + 0.2 * $eff_height;
    $group_space_height = $eff_height * 0.8;
    $group_row_size = $group_space_height / ( $group_row_count * ( 1 + $group_spacing_factor));
    $eff_group_row_size = $group_row_size * ( 1 + $group_spacing_factor );
}

sub clear{
    $canvas->delete('all');
}

sub Update{
    $canvas->delete('all');
    draw_elements();
    @used_spots = ();
    draw_relations();
}

sub draw_elements{
    my $elements_count = $SWorkspace::elements_count;
    $space_per_elem = $eff_width / ( $elements_count + 2);
    ## $space_per_elem
    ## $Margin
    
    my $counter = 0;
    for my $elt (@SWorkspace::elements) {
        new_object( $elt, $Margin + (0.5+$counter) * $space_per_elem,
                    $Margin + $eff_height * 0.05
                        );
        $canvas->createLine( $Margin + ( 1 + $counter ) * $space_per_elem,
                           $Margin,
                           $Margin + ( 1 + $counter ) * $space_per_elem,
                           $Height - $Margin,
                           @line_options,
                               );
        $counter++;
    }

}

sub draw_relations{
    for my $rel (values %SWorkspace::relations) {
        $rel->draw();
    }
}


sub new_object{
    my ( $obj ) = shift;
    my $id = $obj->draw( @_ );
    $Id2Obj{$id} = $obj;
    return $id;
}

sub SReln::draw{
    my ( $reln ) = @_;
    my $from = $reln->get_first;
    my $to   = $reln->get_second;
    my ($l1, $l2, $r1, $r2) = ($from->get_left_edge(), $to->get_left_edge(),
                               $from->get_right_edge(), $to->get_right_edge());
    my ($left, $right) = (min($l1, $l2), max($r1, $r2));

    my $row = get_next_available_row($left, $right);
    draw_logical_rectangle( $row, $left, $right, \@reln_bgd_options);
    draw_logical_rectangle( $row, $l1, $r1, \@reln_fgd_options, 0, 0.5);
    draw_logical_rectangle( $row, $l2, $r2, \@reln_fgd_options, 0.5, 1);
}


sub SElement::draw{
    my ( $self ) = shift;
    $canvas->createText( @_, @element_options,
                         -text => $self->get_mag(),
                         -tags => [$self, "wso"],
                             );
}

sub draw_logical_rectangle{
    my ( $row, 
         $start_col, 
         $end_col, 
         $options, 
         $start_fraction, 
         $end_fraction ) = @_;
    $start_fraction ||= 0;
    $end_fraction ||= 1;
    ($start_col, $end_col) = minmax($start_col, $end_col);
    my $x1 = $Margin + $space_per_elem * ($start_col + 0.1);
    my $x2 = $Margin + $space_per_elem * ($end_col + 1 - 0.1);
    my $y  = $group_space_offset + $eff_group_row_size * $row;
    my $y1 = $y + $start_fraction * $group_row_size;
    my $y2 = $y + $end_fraction * $group_row_size;
    $canvas->createRectangle($x1, $y1, $x2, $y2, @$options);
}

sub get_next_available_row{
    my ( $left, $right ) = @_;
    ROW_LOOP: for my $row_no (0..$group_row_count-1) {
        my $row_hash = ($used_spots[$row_no] ||= {});
        for my $idx ($left..$right) {
            next ROW_LOOP if exists $row_hash->{$idx};
        }
        # looks good!
        for my $idx ($left..$right) {
            $row_hash->{$idx} = 1;
        }
        return $row_no;
    }
    SErr->throw("looks like $group_row_count are too few rows! ran out of space");
}


1;
