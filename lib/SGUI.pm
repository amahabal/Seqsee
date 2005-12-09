package SGUI;
use strict;
use Config::Std;
use Tk::SCoderack;
use Tk::SStream;
use Tk::SComponents;

our $MW;
our $Coderack;
our $Stream;
our $Components;
our $Workspace;


sub setup{
    read_config 'config/GUI.conf' => my %config;

    $MW = new MainWindow;
    setup_bindings($MW);

    my $button_frame = $MW->Frame()->pack(-side => 'top');
    my $main_frame   = $MW->Frame()->pack(-side => 'top');
    setup_buttons($button_frame);

    $config{coderack}{-tags_provided} = tags_to_aref( $config{coderack_tags});
    $Coderack = $main_frame->SCoderack(%{ $config{coderack} })
        ->pack(-side => "left");

    $config{stream}{-tags_provided} = tags_to_aref( $config{stream_tags});
    $Stream = $main_frame->SStream(%{ $config{stream} })
        ->pack(-side => "left");

    $config{components}{-tags_provided} = 
        tags_to_aref( $config{components_tags});
    $Components = $main_frame->SComponents(%{ $config{components} })
        ->pack(-side => "left");

    $Workspace = $MW->SWorkspace( %{ $config{workspace} })
        ->pack(-side => "top", - fill => "x");

}

sub Update{
    $Coderack->Update();
    $Stream->Update();
    $Components->Update();
    $Workspace->Update();
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
    $mw->bind('<KeyPress-q>' => sub {
                  exit;
              });

    
}


1;
