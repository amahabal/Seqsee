package main;
use Tk;
use Tk::LabFrame;

use Tk::SWorkspace;
use Tk::SInfo;
use Tk::SStream;
use Tk::SCoderack;
use Tk::SStream;
use Tk::SNet;
 
our $MW;
our $WS_gui;
our $Info_top;
our $INFO;
our $CODERACK_gui;
our $SLIPNET_gui;
our $CR_SN_top;

sub setupGUI{
  # This method creates windows etc...
  $MW = new MainWindow;
  $WS_gui = $MW->SWorkspace
    (
     -height      => 500,
     -width       => 700,
     -background  => '#FCFCFC'
    )
      ->pack(-side => 'top');

  # $CR_SN_top = $MW->Toplevel;
  $Info_top = $MW->Toplevel;
  $INFO     = $Info_top->Scrolled
    ('SInfo',
     -scrollbars  => 'se',
     -height      => 33,
     -width       => 60,
     -background  => '#FCFCFC'
    )
      ->pack(-side => 'left');
  my $frame = $Info_top->Frame()->pack(-side => 'right');
  my $f2 = $frame->LabFrame(-label => "Coderack")
    ->pack(-side => 'top');
  $CODERACK_gui = $f2->SCoderack
    ( 
      -foreground => 'blue',
      -textwidth  => 15,
      -width      => 0,
      -selectmode => 'browse',  
    )->pack(-side => 'top');
  $f2 = $frame->LabFrame(-label => "Slipnet")
    ->pack(-side => 'top');
  $SLIPNET_gui = $f2->SNet
    (
     -foreground => 'blue',
     -textwidth  => 22,
     # -width      => 0,
     -selectmode => 'browse',  
    )->pack();

  $STREAM_gui = $MW->SStream;

  #$Stream_top = $MW->Toplevel;
  #$STREAM_gui = $Stream_top->SCrolled
  #  (
  #
  #				     )

  $WS_gui->redraw;
  $MW->Button(-text => "Step",
	      -command => sub { Step(); 
				print "Finished step $CurrentEpoch\n";
			      }
	     )->pack;
}

sub SElement::display_details{
  my $self = shift;
  $INFO->clear;
  $INFO->head("$self\tMag: $self->{mag}");
  $INFO->skip(1);
  $self->display_descriptions;
  $INFO->skip(3);
  $self->display_memberships;
  $INFO->skip(3);
  $INFO->history($self);
}

sub SBond::display_details{
  my $self = shift;
  $INFO->clear;
  $INFO->head("$self\t$self->{str}");
  $INFO->skip(1);
  $self->display_bdescriptions;
  $INFO->skip(3);
  $INFO->history($self);
}

sub SDescs::display_descriptions{
  my $self = shift;
  my $depth = shift || 1;
  $INFO->head2("Descriptions");
  for my $desc (@{ $self->{descs} }) {
    $INFO->description($desc, $depth);
  }
}

sub SBDescs::display_bdescriptions{
  my $self = shift;
  my $depth = shift || 1;
  $INFO->head2("Descriptions");
  for my $desc (@{ $self->{descs} }) {
    $INFO->bdescription($desc, $depth);
  }
}

sub SObject::display_memberships{
  my $self = shift;
  my $depth = shift || 1;
  $INFO->head2("Bonds");
  foreach (values %{$self->{bonds}}, values %{$self->{bonds_p}}) {
    $INFO->bond($_, $depth);
  }
  $INFO->skip(1);
  $INFO->head2("Groups");
  foreach (values %{$self->{groups}}, values %{$self->{groups_p}}) {
    $INFO->group($_, $depth);
  }
}

1;
