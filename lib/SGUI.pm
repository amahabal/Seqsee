package SGUI;
use strict;
use warnings;
use Carp;
use Config::Std;
use English qw(-no_match_vars);
use Tk::SCoderack;
use Tk::SStream;
use Tk::SComponents;
use Tk::SInfo;
use Tk::SWorkspace;
use Smart::Comments;

our $MW;
our $Coderack;
our $Stream;
our $Components;
our $Workspace;
our $Info;

sub setup {
    read_config 'config/GUI_classic.conf' => my %config;
    CreateWidgets( \%config );
    SetupButtons( \%config );
    SetupBindings( \%config );
}

sub Update {
    $Coderack->Update();
    $Stream->Update();
    $Components->Update();
    $Workspace->Update();
    if ($SCoderack::LastSelectedRunnable) {
        $SCoderack::LastSelectedRunnable->display_self($Info);
        $Info->insert( '0.0', "Last Run Runnable:", "heading", "\n\n" );
    }

    #XXX why does this fail?
    $Info->insert_autoTagged( 'end', $Global::LogString );
    $MW->update();
}

sub tags_to_aref {
    my ($href) = @_;
    my @ret = ();
    while ( my ( $k, $v ) = each %$href ) {
        push @ret, [ $k, split( /\s+/, $v ) ];
    }
    return \@ret;
}

sub ask_seq {
    my $top = $MW->Toplevel( -title => "Seqsee Sequence Entry" );
    $top->Label( -text => "Enter sequence(space separated): " )->pack( -side => 'left' );
    $top->focusmodel('active');
    my $e = $top->Entry()->pack( -side => 'left' );
    $e->focus();
    $e->bind(
        '<Return>' => sub {
            my $v = $e->get();
            $v =~ s/^\s+//;
            $v =~ s/\s+$//;
            my @seq = split( /[,\s]+/, $v );
            print "Return pressed; Seq is: @seq";
            SWorkspace->clear();
            SWorkspace->insert_elements(@seq);
            Update();
            $top->destroy;
        }
    );

}

sub CreateWidgets {
    my ($config_ref) = @_;
    $MW = new MainWindow();

    my $frames_string = $config_ref->{frames}{frames} or confess;
    my @lines = split qq{\n}, $frames_string;
    for my $line (@lines) {
        $line =~ s#^\s*##;
        $line =~ s#\s*$##;
        my ( $name, $parent, $widget_type, $position, @rest ) = split( /\s+/, $line );
        ## In CreateWidgets: $name, $parent, $widget_type, $position, @rest
        no strict;
        my $widget
            = ${$parent}->$widget_type( GetWidgetOptions( $widget_type, $config_ref, @rest ) )
            ->pack( -side => $position );
        ${$name} = $widget unless $name eq '_';
    }
}

sub SetupButtons {
    my ($config_ref) = @_;

    my $parent_name = $config_ref->{frames}{buttons_widget} or confess;
    my $parent;
    { no strict; $parent = ${$parent_name}; }

    my $button_order = $config_ref->{frames}{button_order} or confess;
    my @buttons_names = map { s#^\s*##; s#\s*$##; s#\s+# #g; $_ } split( qq{\n}, $button_order );

    my $options_ref = $config_ref->{Button};
    my %options = ( defined $options_ref ) ? %$options_ref : ();

    for (@buttons_names) {
        my $command_string = $config_ref->{buttons}{$_} or confess;
        my $command = eval qq{ sub {$command_string}; };
        confess if $EVAL_ERROR;
        $parent->Button( -text => $_, -command => $command, %options )->pack( -side => 'left' );
    }
}

sub SetupBindings {
    my ($config_ref) = @_;
    my @names = keys %{ $config_ref->{bindings} };
    for my $name (@names) {
        ## $name: $name
        my $command_string = $config_ref->{bindings}{$name} or confess;
        my $command = eval qq{ sub {$command_string}; };
        confess if $EVAL_ERROR;
        $MW->bind( $name => $command );
    }
}

{
    my %SeqseeWidgets = map { $_ => 1 } qw(SCoderack SStream SComponents SInfo SWorkspace);

    sub GetWidgetOptions {
        my ( $type, $config_ref, @rest ) = @_;
        if ( exists $SeqseeWidgets{$type} ) {
            my %ret = %{ $config_ref->{$type} } or confess;
            my $tags_config = $config_ref->{ $type . '_tags' };
            if ( defined $tags_config ) {
                $ret{'-tags_provided'} = tags_to_aref($tags_config);
            }
            return ( %ret, @rest );

        }
        else {
            my $extra_config = $config_ref->{$type};
            my %extra_config = ( defined $extra_config ) ? %$extra_config : ();
            return ( %extra_config, @rest );
        }
    }
}

1;
