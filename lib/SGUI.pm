package main;
use Tk;
use Tk::SWorkspace;
use Tk::SInfo;
 
our $MW;
our $WS_gui;
our $Info_top;
our $INFO;

sub setupGUI{
  # This method creates windows etc...
  $MW = new MainWindow;
  $WS_gui = $MW->SWorkspace
    (
     -height      => 500,
     -width       => 700,
     -background  => '#FCFCFC'
    )
      ->pack();
  $Info_top = $MW->Toplevel;
  $INFO     = $Info_top->Scrolled
    ('SInfo',
     -scrollbars  => 'se',
     -height      => 33,
     -width       => 80,
     -background  => '#FCFCFC'
    )
      ->pack;

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
  $INFO->head("SElement $self\tMag: $self->{mag}");
  $INFO->body(1, "Other info not yet compiled");
}

1;
