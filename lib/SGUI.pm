package main;
use Tk;
use Tk::LabFrame;
use Tk::Menu;

use Tk::SWorkspace;
use Tk::SInfo;
use Tk::SStream;
use Tk::SCoderack;
use Tk::SStream;
use Tk::SNet;
use Tk::Pod;
 
our $MW;
our $WS_gui;
our $Info_top;
our $INFO;
our $CODERACK_gui;
our $SLIPNET_gui;
our $CR_SN_top;
our $MENU;

Tk::Pod->Dir('.', './pod/sdd', './pod');

sub setupGUI{
  # This method creates windows etc...
  $MW = new MainWindow;
  setup_menu();
  $WS_gui = $MW->SWorkspace
    (
     -height      => 500,
     -width       => 700,
     # -background  => '#FCFCFC'
    )
      ->pack(-side => 'top');

  # $CR_SN_top = $MW->Toplevel;
  $Info_top = $MW->Toplevel;
  $INFO     = $Info_top->Scrolled
    ('SInfo',
     -scrollbars  => 'se',
     -height      => 33,
     -width       => 60,
     #-background  => '#FCFCFC'
    )
      ->pack(-side => 'left');
  my $frame = $Info_top->Frame()->pack(-side => 'right');
  my $f2 = $frame->LabFrame(-label => "Coderack")
    ->pack(-side => 'top');
  $CODERACK_gui = $f2->Scrolled
    ( 'SCoderack',
      -scrollbars => 'oe',
      -foreground => 'blue',
      -width      => 40,
      -height     => 12,
    )->pack(-side => 'top');
  $f2 = $frame->LabFrame(-label => "Slipnet")
    ->pack(-side => 'top');
  $SLIPNET_gui = $f2->Scrolled
    ( 'SNet',
      -scrollbars => 'oe',
      -foreground => 'blue',
      -width      => 40,
      -height     => 18,
    )->pack();
  $SLIPNET_gui->redraw;
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
  $self->display_fascinations;
  $INFO->skip(3);
  $self->display_memberships;
  $INFO->skip(3);
  $INFO->history($self);
}

sub SGroup::display_details{
  my $self = shift;
  $INFO->clear;
  $INFO->head("$self\t$self->{str}");
  $INFO->skip(1);
  $self->display_descriptions;
  $INFO->skip(3);
  $self->display_fascinations;
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
  $self->display_fascinations;
  $INFO->skip(3);
  $INFO->history($self);
}

sub SNode::display_details{
  my $self = shift;
  $INFO->clear;
  $INFO->head("$self\t$self->{str}");
  $INFO->skip(1);
  $self->display_descriptions;
  $INFO->skip(3);
  $self->display_fascinations;
}

sub SDescs::display_descriptions{
  my $self = shift;
  my $depth = shift || 1;
  my $title = $self->isa("SNode")? "Links" : "Descriptions";
  $INFO->head2($title);
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

sub SFascination::display_fascinations{
  my $self = shift;
  $INFO->head2("Fascinations");
  while (my ($k, $v) = each %{$self->{f}}) {
    $INFO->body(1, "$k\t$v");
  }
}

##### MENU SETUP
sub setup_menu{
  $MENU = $MW->Menu(-type => 'menubar');
  $MW->configure(-menu => $MENU);
 
  # File
  my $f = $MENU->cascade(-label => '~File', -tearoff => 0);
  $f->command(-label => 'Exit', -command => ['exit']);

  # Info
  my $i = $MENU->cascade(-label => '~Information', -tearoff => 0);
  $i->command(-label   => 'Codelet types',
	      -command => [\&display_file, "SCF.list"],
	     );
  my $j = $i->cascade(-label => 'Who launches...', -tearoff => 0);
  my $k = $i->cascade(-label => '... launched by', -tearoff => 0);
  populate_launching_info($j, $k);

  $i = $MENU->command(-label   => 'Help',
		      -command => sub { 
			$MW->Pod()->configure(-file => "index");
		      }
		     );
}

sub display_file{
  my $filename = shift;
  open(IN, $filename) or die "Could not open file $filename";
  $INFO->clear;
  $INFO->head($filename);
  $INFO->skip(1);
  while ($in = <IN>) {
    $INFO->insert('end', $in);
  }
  close IN;
}

sub display_launching_info{
  my ($launcher, $launchee) = @_;
  $INFO->clear;
  if ($launcher) {
    open (IN, "perl GenCL.pl --info --launcher=$launcher|");
    $INFO->head("Launched by $launcher");
    while ($in = <IN>) {
      # Read launcher in, ignore it.
      my $family = <IN>; $family =~ s(^(.*)#)();
      my $TAG = <IN>; $TAG =~ s(^(.*)#)(); chop($TAG);
      my $key = <IN>; $key =~ s(^(.*)#)();
      my $urgency = <IN>; $urgency =~ s(^(.*)#)();
      my $prob = <IN>; $prob =~ s(^(.*)#)();
      my $ignore = <IN>;
      $INFO->skip(1);
      $INFO->head2($family);
      $INFO->body(1, "urgency      =>  $urgency");
      $INFO->body(1, "probability  =>  $prob");
      $INFO->body(1, "tag/key      =>  $TAG/$key");
    }
    close(IN);
  } else {
    open (IN, "perl GenCL.pl --info --launchee=$launchee|");
    $INFO->head("Who launches $launchee");
    while ($in = <IN>) {
      my $launcher = $in; $launcher =~ s(^(.*)#)();
      my $family = <IN>; $family =~ s(^(.*)#)();
      my $TAG = <IN>; $TAG =~ s(^(.*)#)();chop($TAG);
      my $key = <IN>; $key =~ s(^(.*)#)();
      my $urgency = <IN>; $urgency =~ s(^(.*)#)();
      my $prob = <IN>; $prob =~ s(^(.*)#)();
      my $ignore = <IN>;
      $INFO->skip(1);
      $INFO->head2($launcher);
      $INFO->body(1, "urgency      =>  $urgency");
      $INFO->body(1, "probability  =>  $prob");       
      $INFO->body(1, "tag/key      =>  $TAG/$key");
    }
    close(IN);
  }
}

sub populate_launching_info{
  my ($who_launches, $launched_by) = @_;
  $launched_by->command(-label   => "Startup",
			-command => [\&display_launching_info, "StartUp"]
		       );
  $launched_by->command(-label   => "Background",
			-command => [\&display_launching_info, "Background"]
		       );
  $launched_by->separator;
  open(IN, "SCodeConfig.list");
  while (my $in = <IN>) {
    chop($in);
    last unless $in;
    next if $in eq "StartUp";
    next if $in eq "Background";
    $launched_by->command(-label => $in,
			  -command => [\&display_launching_info, $in]
			 );
  }
  while (my $in = <IN>) {
    chop($in);
    $who_launches->command(-label => $in,
			  -command => [\&display_launching_info, '',  $in]
			 );
  }
  close(IN);
}

1;
