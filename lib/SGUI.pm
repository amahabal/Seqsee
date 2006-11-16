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
use Tk::SActivation;
use Smart::Comments;

our $MW;
our $Coderack;
our $Stream;
our $Components;
our $Workspace;
our $Info;
our $Activations;

sub setup {
    my ($options_ref) = @_;
    my $gui_config_name = $options_ref->{gui_config} or confess;
    my $config_filename = "config/${gui_config_name}.conf";
    read_config $config_filename => my %config;
    CreateWidgets( \%config );
    SetupButtons( \%config );
    SetupBindings( \%config );
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

sub SetupButtons {
    my ($config_ref) = @_;

    my $parent_name = $config_ref->{frames}{buttons_widget} or confess;
    my $parent;
    { no strict; $parent = ${$parent_name}; }
    ## parent: $parent_name, $parent

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
    my %SeqseeWidgets
        = map { $_ => 1 } qw(SCoderack SStream SComponents SInfo SWorkspace SActivation);
    my %Updatable = map { $_ => 1 } qw(SCoderack SStream SComponents SWorkspace SActivation);
    my @to_Update = ();

    sub CreateWidgets {
        my ($config_ref) = @_;

        my $MW_options = $config_ref->{MainWindow} || {};
        $MW = new MainWindow(%$MW_options);

        my $frames_string = $config_ref->{frames}{frames} or confess;
        my @lines = split qq{\n}, $frames_string;
        for my $line (@lines) {
            $line =~ s#^\s*##;
            $line =~ s#\s*$##;
            my ( $name, $parent, $widget_type, $position, @rest ) = split( /\s+/, $line );
            ## In CreateWidgets: $name, $parent, $widget_type, $position, @rest
            no strict;
            my $widget
                = ${$parent}->$widget_type( GetWidgetOptions( $widget_type, $config_ref, @rest ) );
            $widget->pack( -side => $position ) unless $widget_type eq 'Toplevel';
            ${$name} = $widget unless $name eq '_';

            if ( $Updatable{$widget_type} ) {
                push @to_Update, $widget;
            }
        }
    }

    sub GetWidgetOptions {
        my ( $type, $config_ref, @rest ) = @_;
        if ( exists $SeqseeWidgets{$type} ) {
            exists( $config_ref->{$type} ) or confess "Missing config for $type";
            my %ret         = %{ $config_ref->{$type} };
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

    sub Update {
        for (@to_Update) {
            $_->Update();
        }

        if ($SCoderack::LastSelectedRunnable) {
            $SCoderack::LastSelectedRunnable->display_self($Info);
            $Info->insert( '0.0', "Last Run Runnable:", "heading", "\n\n" );
        }

        #XXX why does this fail?
        $Info->insert_autoTagged( 'end', $Global::LogString );
        $MW->update();
    }

}

1;
