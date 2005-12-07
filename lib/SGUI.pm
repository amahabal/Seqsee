package SGUI;
use strict;
use Config::Std;

our $MW;
our $Coderack;
our $Stream;

sub setup{
    read_config 'config/GUI.conf' => my %config;

    $MW = new MainWindow;
    my $button_frame = $MW->Frame()->pack(-side => 'top');
    my $main_frame   = $MW->Frame()->pack(-side => 'top');
    setup_buttons($button_frame);

    $config{coderack}{-tags_provided} = tags_to_aref( $config{coderack_tags});
    $Coderack = $main_frame->SCoderack(%{ $config{coderack} })
        ->pack(-side => "left");

    $config{stream}{-tags_provided} = tags_to_aref( $config{stream_tags});
    $Stream = $main_frame->SStream(%{ $config{stream} })
        ->pack(-side => "left");

}

sub Update{
    $Coderack->Update();
    $Stream->Update();
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
