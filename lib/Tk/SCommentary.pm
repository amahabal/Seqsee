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
my $active_button_count;

my $Response;    # Button pressed. When message displayed requiring action,
                 # this is the variable waited on.

Construct Tk::Widget 'SCommentary';

sub Update {
}

sub Populate {
    my ( $self, $args ) = @_;
    my $tags_ref = delete $args->{-tags_provided};
    my $font = delete $args->{-font};

    $Text =
      $self->Scrolled( 'ROText', -scrollbars => 'se', -font => $font, %$args )
      ->pack( -side => 'left' );
    $Text->bind( '<KeyPress>',   sub { Tk->break() } );
    $Text->bind( '<KeyPress-q>', sub { exit } );

    for (@$tags_ref) {
        print "Configuring $_->[0]\n";
        $Text->tagConfigure(@$_);
    }

    $ButtonFrame = $self->Frame()->pack( -side => 'right' );
    for my $button_number ( 0 .. 3 ) {
        push @Buttons,
          $ButtonFrame->Button(
            -text    => '',
            -command => sub { $Response = $button_number },
            -width   => 15,
            -state   => 'disabled',
          )->pack( -side => 'top' );
        my $key_to_press_to_activate = $button_number + 1;
        $Text->bind(
            "<KeyPress-$key_to_press_to_activate>",
            sub {
                return unless $button_number < $active_button_count;
                $Response = $button_number,;
            }
        );
    }
}

sub MessageRequiringNoResponse {
    my ( $self, @msg ) = @_;
    $Text->insert( 'end', @msg );
    $Text->see('end');
}

sub MessageRequiringAResponse {
    my ( $self, $response_ref, @msg ) = @_;
    $Text->insert( 'end', @msg );
    $Text->see('end');

    my $i = 0;
    for (@$response_ref) {
        $Buttons[$i]->configure( -text => $_, -state => 'normal' );
        $i++;
    }
    $active_button_count = $i;

    $Response = -1;
    $Text->focus();
    $self->grab();
    $SGUI::MW->waitVariable( \$Response );
    $self->grabRelease();
    $SGUI::Workspace->focus();
    $active_button_count = 0;
    for ( 0 .. 3 ) {
        $Buttons[$_]->configure( -text => '', -state => 'disabled' );
    }
    my $response = $response_ref->[$Response];
    $Text->insert('end', '  ', [], $response, ['user_response'], "\n");
    return $response;
}

sub MessageRequiringBooleanResponse {
    my ( $self, @msg ) = @_;
    my $res = $self->MessageRequiringAResponse( [ 'yes', 'no' ], @msg );

    #main::message("Response: *$res*");
    return ( $res eq 'yes' ) ? 1 : 0;
}

1;

