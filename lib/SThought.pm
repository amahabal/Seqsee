package SThought;
use strict;

use Class::Std;
use Carp;

 
# variable: %fringe_of
#    Keeps the fringe of the the thought
my %stored_fringe_of :ATTR( :get<stored_fringe>, :set<stored_fringe> );


# variable: %_Type2Class
#    Converts type to a class name
my %_Type2Class = 
    qw(   SElement        SThought::SElement
          SAnchored       SThought::SAnchored
          SReln::Simple   SThought::SReln_Simple
           );

# method: create
# creates a though given the core
#
sub create{
    my ( $package, $core ) = @_;
    my $type = ref $core;
    my $class = $_Type2Class{$type};

    confess "Don't know how to create object of type $type"
        unless $class;

    return $class->new( { core => $core });
}



# method: schedule
# schedules self as a scheduled thought
#
#    Parallels a method in SCodelet that adds itself to the coderack.
sub schedule{
    my ( $self ) = @_;
    SCoderack->schedule_thought( $self );
}



# method: force_to_be_next_runnable
# 
#
sub force_to_be_next_runnable{
    my ( $self ) = @_;
    SCoderack->force_thought( $self );
}



1;


