package Tk::SWorkspace;
use strict;
use Config::Std;
use Smart::Comments;
use Tk::widgets qw{Canvas};
use base qw/Tk::Derived Tk::Canvas/;

our $canvas;
our %Id2Obj;
my ($Height, $Width, $Margin);
my (@element_options, @line_options, @reln_bgd_options, @reln_fgd_options,
    @group_bgd_options, @group_fgd_options
        );
my ($space_per_elem);

BEGIN {
    read_config 'config/GUI_ws.conf' => my %config;
    @element_options  = %{$config{elements}};
    @line_options     = %{$config{line}};
    @reln_bgd_options = %{$config{reln_bgd}}; 
    @reln_fgd_options = %{$config{reln_fgd}}; 
    @group_bgd_options = %{$config{group_bgd}}; 
    @group_fgd_options = %{$config{group_fgd}}; 
    $Margin            = $config{placing}{-margin};
}

Construct Tk::Widget 'SWorkspace';

sub Populate{
    my ( $self, $args ) = @_;
    my $element_choices = delete $args->{-element_choices};
    $canvas = $self;
    $Height = $canvas->cget('height');
    $Width  = $canvas->cget('width');

    print "Width: $Width\n";
}

sub clear{
    $canvas->delete('all');
}

sub Update{
    $canvas->delete('all');
    draw_elements();
}

sub draw_elements{
    my $elements_count = $SWorkspace::elements_count;
    my $eff_width  = $Width - 2 * $Margin;
    my $eff_height = $Height - 2 * $Margin;
    $space_per_elem = $eff_width / ( $elements_count + 2);
    ## $space_per_elem
    ## $Margin
    
    my $counter = 0;
    for my $elt (@SWorkspace::elements) {
        new_object( $elt, $Margin + (0.5+$counter) * $space_per_elem,
                    $Margin + $eff_height * 0.5
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

sub new_object{
    my ( $obj ) = shift;
    my $id = $obj->draw( @_ );
    $Id2Obj{$id} = $obj;
    return $id;
}

sub SElement::draw{
    my ( $self ) = shift;
    $canvas->createText( @_, @element_options,
                         -text => $self->get_mag(),
                         -tags => [$self, "wso"],
                             );
}


1;
