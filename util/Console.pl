use strict;
use Tk;
use Tk::StatusBar;
use Smart::Comments;

$SIG{INT} = sub  {
    
};

$SIG{SIGHUP} = sub  {
    exit;
};


my $MW = new MainWindow();
my $SB = $MW->StatusBar();
my $StatusMsg = "";
$SB->addLabel(-textvariable => \$StatusMsg);

my $button_frame = $MW->Frame()->pack(-side => 'bottom');
my $buttons_per_row = 3;

CreateSeqseeLaunchingFrame();

my @input_requiring_commands_config = (
    [ "RunMultipleTimes",
      [
          [ "Terms",
            "1 1 2 1 2 3 | 1 2 3 4 1 2 3 4 5 1 2 3 4 5 6",
                ],
              ],
      [ # Command constructor
          'CreateRunPerlScriptCommand',
          qw{util/RunMultipleTimes.pl},
          10,
          qq{"\$Terms"},
              ],
          ],
    ["Search", #command name
     [ # inputs
         ["SearchString", #input name
          "S", # default
              ]
             ],
     [ # Command constructor
         'CreateRunPerlScriptCommand',
         qw{util/Search.pl}, 
         qq{\$SearchString}, 
         ],
        ],
);

INSERT_INPUT_REQUIRING_COMMANDS: {
    for my $cmd_config (@input_requiring_commands_config) {
        my ($command_name, $inputs, $command) = @$cmd_config;
        my $frame = $MW->LabFrame(-label=>$command_name,
                                  -labelside => 'acrosstop'
                                      )->pack(-side => 'top');
        my %Inputs;
        for my $input_config (@{$inputs}) {
            my ($name, $default) = @$input_config;
            my $__this_var = $default;
            $Inputs{$name} = \$__this_var;
            print "SET \$Inputs{$name}\n";
            my $subframe = $frame->Frame()->pack(-side => 'top');
            $subframe->Label(-text => $name)->pack(-side => 'left');
            $subframe->Entry(-textvariable => \$__this_var)->pack(-side => 'left');
        }

        $frame->Button(-text => 'Go', -command => sub {
                           my ($cmd_constructor, @args) = @{$command};
                           ### old args: @args
                           @args = map { 
                               my $string = $_;
                               $string =~ s<\$([a-zA-Z_][a-zA-Z0-9_]*)>
                                           <print "SAW $1#", %Inputs, "\n";
                                           if (exists($Inputs{$1})) {
                                               print "$1 exists in \%Inputs\n";
                                               ${$Inputs{$1}}
                                           } else {
                                               print "$1 missing from \%Inputs\n";
                                               $1
                                           }>ge;
                               $string;
                           } @args;
                           ### new args: @args
                           #<STDIN>;
                           no strict;
                           my $cmd = $cmd_constructor->(@args);
                           $cmd->();
                       })->pack(-side => 'top');
    }
}

my @button_config = (
    [Compile => CreateRunPerlScriptCommand('Compiler\Compile.pl')],
    [DeleteGenlib => sub  {
         unlink(<genlib/*.pm>);
         unlink(<genlib/*/*.pm>);
         unlink(<genlib/*/*.pm>);
     }
         ],
    [CPAN => CreateRunPerlScriptCommand(qw{-MCPAN -e shell})],
    [SVNDiff => CreateRunPerlScriptCommand('util\ShowDiff.pl')],
    [RunTests => CreateRunPerlScriptCommand('c:\Perl\bin\prove.bat', 't\*')],
    [ClearMemory => sub  {
         open my $MEMORY_HANDLE, '>', 'memory_dump.dat';
         print {$MEMORY_HANDLE} ' ';
         close $MEMORY_HANDLE;
     }
         ],
    [ShowCodeletGraph => CreateRunPerlScriptCommand('util\CodeletCallGraph.pl')],
);

INSERT_BUTTONS: {
    my $button_count = 0;
    my $button_subframe;
    for my $button_info (@button_config) {
        my ($text, $command) = @{$button_info};
        ### t, c: $text, $command
        if ($button_count % $buttons_per_row == 0) {
            $button_subframe = $button_frame->Frame()->pack(-side => 'top');
        }
        $button_count++;
        $button_subframe->Button(-text => $text,
                                 -command => $command,
                                 -width => 30,
                                     )->pack(-side => 'left');
    }
}

MainLoop();

sub CreateRunSystemCommand {
    my ( @cmd ) = @_;
    return sub {
        system("cls");
        $StatusMsg = "Starting subprocess...";
        system(@cmd);
        $StatusMsg = "Done.";
    };
}

sub CreateRunPerlScriptCommand {
    my ( @args ) = @_;
    return CreateRunSystemCommand('c:\Perl\bin\perl', @args);
}

sub CreateSeqseeLaunchingFrame {
    my $frame = $MW->LabFrame(-label => 'Run Seqsee',
                              -labelside => 'acrosstop'
                                  )->pack(-side => 'top');
    my $Sequence;
    {
        my $subframe = $frame->Frame()->pack(-side => 'top');
        $subframe->Label(-text => "Sequence: ")->pack(-side=> 'left');
        $subframe->Entry(-textvariable => \$Sequence)->pack(-side=>'left');
    }
    my $View;
    {   # Should be a pulldown!
        use lib 'genlib';
        use Tk::Seqsee;
        use Tk::ComboEntry;
        my @view_options = @Tk::Seqsee::ViewOptions;
        my @options_to_list;
        my %names_to_values;

        my $counter = 0;
        for (@view_options) {
            my $name = $_->[0];
            $names_to_values{$name} = $counter++;
            push @options_to_list, $name;
        }

        my $subframe = $frame->Frame()->pack(-side => 'top');
        $subframe->Label(-text => "View: ")->pack(-side=> 'left');
        # $subframe->Entry(-textvariable => \$View)->pack(-side=>'left');
        $subframe->ComboEntry(-itemlist => \@options_to_list,
                              -invoke => sub  {
                                  my ($comboentry) = @_;
                                  my $choice = $comboentry->get();
                                  $View = $names_to_values{$choice};
                              },
                              -width => 40,
                              -showmenu => 1,
                                  )->pack(-side => 'left');
    }
    use lib 'genlib';
    use Global;
    my %PossibleFeatures = %Global::PossibleFeatures;
    my %FeatureValues = map { $_ => 0 } keys %PossibleFeatures;
    {
        my $subframe = $frame->LabFrame(-label => 'Optional Features',
                                        -labelside => 'acrosstop'
                                            )->pack(-side=> 'top');
        my @features = sort keys %FeatureValues;
        my $space_left_in_current_row=0;
        my $subsubframe;
        while (@features) {
            if (!$space_left_in_current_row) {
                $subsubframe = $subframe->Frame()->pack(-side=>'top');
                $space_left_in_current_row = 3;
            }
            my $feature = shift(@features);
            $subsubframe->Checkbutton(-variable => \$FeatureValues{$feature},
                                      -text => $feature,
                                          )->pack(-side => 'left');
        }
    }
    $frame->Button(-text => 'RUN SEQSEE',
                   -command => sub  {
                       my @features_turned_on = grep { $FeatureValues{$_}} keys %FeatureValues;
                       my @feature_related_arguments = map { "-f=$_" } @features_turned_on;
                       my @cmds = ( "Seqsee.pl",
                                    qq{--seq=$Sequence},
                                   qq{--view=$View},
                                   @feature_related_arguments,
                                       );
                       my $subprocess_cmd = CreateRunPerlScriptCommand(@cmds);
                       $subprocess_cmd->();
                       print "View was $View\n";
                   }
                       )->pack(-side=>'top');
}
