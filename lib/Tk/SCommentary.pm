package Tk::SCommentary;
use strict;
use warnings;
use Carp;
use Config::Std;
use Smart::Comments;
use Tk::widgets qw{Canvas};
use List::Util qw(min max);
use Sort::Key qw(rikeysort);
use base qw/Tk::Derived Tk::Frame/;

my $Text;
my $ButtonFrame;
my @Buttons;

my $Response; # Button pressed. When message displayed requiring action,
              # this is the variable waited on.

Construct Tk::Widget 'SCommentary';
sub Update{    
}

sub Populate{
    my ( $self, $args ) = @_;
    $Text = $self->Scrolled('ROText', -scrollbars => 'se',  %$args )->pack(-side => 'left');
    $Text->bind('<KeyPress>', sub {Tk->break()});
    $Text->bind('<KeyPress-q>', sub {exit});
    $ButtonFrame = $self->Frame()->pack(-side => 'right');
    for my $button_number (0..3) {
        push @Buttons,
            $ButtonFrame->Button(-text => '',
                                 -command => sub { $Response = $button_number },
                                 -width => 15,
                                 -state => 'disabled',
                                     )->pack(-side => 'top');
    }
}

sub MessageRequiringNoResponse {
    my ( $self, @msg ) = @_;
    $Text->insert('end', @msg);
    $Text->see('end');
}

sub MessageRequiringAResponse{
    my ( $self, $response_ref, @msg ) = @_;
    $Text->insert('end', @msg);
    $Text->see('end');

    my $i = 0;
    for (@$response_ref) {
        $Buttons[$i]->configure(-text => $_, -state => 'normal');
        $i++;
    }
    $Response = -1;
    $Text->focus();
    $self->grab();
    $SGUI::MW->waitVariable(\$Response);
    $self->grabRelease();
    $SGUI::Workspace->focus();
    for (0..3) {
        $Buttons[$_]->configure(-text => '', -state => 'disabled');
    }
    return $response_ref->[$Response];
}

sub MessageRequiringBooleanResponse{
    my ( $self, @msg ) = @_;
    my $res = $self->MessageRequiringAResponse(['yes', 'no'], @msg);
    #main::message("Response: *$res*");
    return ($res eq 'yes') ? 1 : 0;
}


1;

