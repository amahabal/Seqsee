package main;
use Tk;
use Tk::SWorkspace;

our $MW;
our $WS_gui;

sub setupGUI{
  # This method creates windows etc...
  $MW = new MainWindow;
  $WS_gui = $MW->SWorkspace(
			    -height      => 500,
			    -width       => 700,
			    -background  => '#FCFCFC'
			   )
    ->pack();
  $WS_gui->redraw;
  $MW->Button(-text => "Step",
	      -command => sub { Step(); 
				print "Finished step $CurrentEpoch\n";
			      }
	     )->pack;
}

1;
