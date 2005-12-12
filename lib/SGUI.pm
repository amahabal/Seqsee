package SGUI;
use strict;
use Config::Std;
use Tk::SCoderack;
use Tk::SStream;
use Tk::SComponents;
use Tk::SInfo;
use Tk::SWorkspace;

our $MW;
our $Coderack;
our $Stream;
our $Components;
our $Workspace;
our $Info;

sub setup{
    read_config 'config/GUI.conf' => my %config;

    $MW = new MainWindow;
    setup_bindings($MW);

    my $button_frame = $MW->Frame()->pack(-side => 'top');
    my $main_frame   = $MW->Frame()->pack(-side => 'top');
    my $bottom_frame = $MW->Frame()->pack(-side => 'top');
    my $tmp_frame;
    setup_buttons($button_frame);

    $tmp_frame = $main_frame->Frame()->pack(-side => 'left');
    $config{coderack}{-tags_provided} = tags_to_aref( $config{coderack_tags});
    $tmp_frame->Label(%{$config{labels}}, -text => "Coderack")->pack(-side => 'top');
    $Coderack = $tmp_frame->SCoderack(%{ $config{coderack} })
        ->pack(-side => "top");

    $tmp_frame = $main_frame->Frame()->pack(-side => 'left');
    $config{stream}{-tags_provided} = tags_to_aref( $config{stream_tags});
    $tmp_frame->Label(%{$config{labels}}, -text => "Stream")->pack(-side => 'top');
    $Stream = $tmp_frame->SStream(%{ $config{stream} })
        ->pack(-side => "top");

    $tmp_frame = $main_frame->Frame()->pack(-side => 'left');
    $config{components}{-tags_provided} = 
        tags_to_aref( $config{components_tags});
    $tmp_frame->Label(%{$config{labels}}, -text => "Components")->pack(-side => 'top');
    $Components = $tmp_frame->SComponents(%{ $config{components} })
        ->pack(-side => "top");



    $config{info}{-tags_provided} = 
        tags_to_aref( $config{info_tags});
    $Info = $bottom_frame->SInfo(%{ $config{info} })
        ->pack(-side => "left");
    $Workspace = $bottom_frame->SWorkspace( %{ $config{workspace} })
        ->pack(-side => "left", -fill => "x");

}

sub Update{
    $Coderack->Update();
    $Stream->Update();
    $Components->Update();
    $Workspace->Update();
    if ($SCoderack::LastSelectedRunnable) {
        $SCoderack::LastSelectedRunnable->display_self($Info);
        $Info->insert('0.0', "Last Run Runnable:", "heading", "\n\n");
    }
    $Info->insert('end', $::LogString);
    $MW->update();
}

sub tags_to_aref{
    my ( $href ) = @_;
    my @ret = ();
    while (my($k, $v) = each %$href) {
        push @ret, [$k, split(/\s+/, $v)];
    }
    return \@ret;
}

sub setup_buttons{
    my ( $frame ) = @_;
    my $button;

    my @names_cmds = (
        [ step => sub {
              main::Interaction_step();
          }],
        [ 'step 5' => sub {
              main::Interaction_step_n({ n => 5, update_after => 5});          }],
        [ continue => sub {
              main::Interaction_continue();
          }],
            );
    for (@names_cmds) {
        my ($name, $cmd) = @$_;
        $button = $frame->Button(-text    => $name,
                                 -command => $cmd,
                                     )->pack(-side => 'left');
    }

}

sub setup_bindings{
    my ( $mw ) = @_;
    $mw->bind('<KeyPress-s>' => sub {
                  main::Interaction_step();
              });
    $mw->bind('<KeyPress-c>' => sub {
                  main::Interaction_continue();
              });
    $mw->bind('<KeyPress-5>' => sub {
                  main::Interaction_step_n({n=>5, update_after=>5});
              });
    $mw->bind('<KeyPress-q>' => sub {
                  exit;
              });

    
}


1;
