package Tk::SStream;

use Tk::X11Font;

use Tk::widgets qw{Canvas ROText};
use base qw/Tk::Toplevel/;

Construct Tk::Widget 'SStream';

our ($c_height, $c_width, $max_items); 
our ($size_of_item);
our $spacing = 10;

our $canvas;
our $component_list;
our $magical_halo;

our %type2str = (
		 SElement => 'Elem',
		 SGroup   => 'Group',
		 SBond    => 'Bond',
		 SNode    => 'Concept',
		);
our %Id2Obj;
our @options  = qw{-anchor center
		   -fill       blue
		   -activefill red
		 };
our @headoptions;
our $head_font; 

our $next_detail_position = 0;

sub ClassInit {
  my ($class, $mw) = @_;
  $class->SUPER::ClassInit( $mw );
}

sub Populate{
  my ($self, $args) = @_;
  $c_height  = delete $args->{-c_height} || 200;
  $c_width   = delete $args->{-c_width}  || 700;
  $max_items = $SStream::MaxThoughts;
  $size_of_item = $c_width / ($max_items + 1);
  $canvas = $self->Canvas(-height => $c_height,
			  -width  => $c_width,
			 )->pack(-side => 'top');
  $canvas->bind('movable', '<Button-1>' => 
	      sub {
		my $objid = $canvas->find('withtag', 'current')->[0];
		my $obj   = $Id2Obj{$objid};
		$obj->display_details;
	      });
  $canvas->createRectangle(3, 3, 
			   $size_of_item - 3, $c_height * 0.4 - 3,
			   -fill  => 'lightgreen',
			  );

  my $frame = $self->Frame()->pack(-side => 'top');
  my $frame2 = $frame->LabFrame(-label => "Extended Halo")
    ->pack(-side => 'left');
  my $frame3 = $frame->LabFrame(-label => "Halo Union")
    ->pack(-side => 'left');

  $component_list = $frame3->Scrolled
    ('ROText', 
     -scrollbars => 'oe',
     -height => 10,
     -width  => 42,
    )->pack(-side => 'top');
  
  $magical_halo = $frame2->Scrolled
    ( 'ROText',
      -height => 10,
      -width  => 42,
      -scrollbars => 'oe',
    )->pack;

  $self->SUPER::Populate( $args );
  $head_font = $self->X11Font(foundry => 'adobe',
			      family  => 'times',
			      point   => 160,
			     );
  @headoptions = (-font => $head_font);

  my $font = $self->X11Font(foundry => 'adobe',
			    family  => 'times',
			    point   => 160,
			   );
  $magical_halo->tag(qw{configure Hit -foreground blue -font}, $font);
  $self;
}

sub redraw{
  $canvas->delete('movable');
  %Id2Obj = ();
  $next_detail_position = 0;
  draw_thought($SStream::CurrentThought, -1)
    if $SStream::CurrentThought;
  my $counter = 0;
  for (@SStream::Thoughts) {
    $next_detail_position = ($next_detail_position + 1) % 3;
    draw_thought($_, $counter);
    $counter++;
  }
  update_componentlist();
}

sub update_componentlist{
  $component_list->delete('0.0', 'end');
  foreach my $comp (sort { $SStream::CompStrength{$b} <=> $SStream::CompStrength{$a} } keys %SStream::CompStrength) {
    my $_strength = sprintf("%4.2f", $SStream::CompStrength{$comp});
    my $name = $SNet::Str2Node{$comp}{shortname}; # Will always exist. 
    $component_list->insert('end', "$_strength   '$name'\n");
  }
}

sub draw_thought{
  my ($thought, $position) = @_;
  # Position is -1 for the current thought....
  my $xpos = $size_of_item * ($position + 1.5);
  my $type = $type2str{ ref($thought) };
  my $id = $canvas->createText($xpos, $c_height * 0.2,
			       @options,
			       @headoptions,
			       -text => $type,
			       -tags => [$thought, "movable"],
			      );
  $Id2Obj{$id} = $thought;
  my $detail_height = (2.5 + $next_detail_position) * 0.2 * $c_height;
  $id = $canvas->createText($xpos, $detail_height,
			    @options,
			    @detailoptions,
			    -text => $thought->{str},
			    -tags => [$thought, "movable"],
			   );
  $Id2Obj{$id} = $thought;
}

sub antiquate_thought{
  # Move all thoughs to the right by $size_of_item...
  $canvas->move('movable', $size_of_item, 0);
}

sub delete_thought{
  my ($self, $thought) = @_;
  for (@{ $canvas->find('withtag', $thought) }) {
    delete $Id2Obj{$_};
  }
  $canvas->delete($thought);
}

sub new_current_thought{
  my ($self, $thought) = @_;
  draw_thought($thought, -1);
  $next_detail_position = ($next_detail_position + 1) % 3;
}

sub magical_halo{
  my ($self, $halo) = @_;
  $magical_halo->delete('0.0', 'end');
  while (my ($k, $v) = each %$halo) {
    my $in_stream = (exists $SStream::CompStrength{$k}) ? "Hit" : "miss";
    my $name = $v->[0];
    $name = $name->{shortname} if ref $name;
    $magical_halo->insert('end', "$v->[2]\t");
    $magical_halo->insert('end', $name, $in_stream);
    $magical_halo->insert('end', "\n");
  }
}
 
1;
