package SThought;
use strict;

use Class::Std;

my %core_of :ATTR( :get<core> );
my %core_type_of :ATTR( :get<core_type> );

sub BUILD{
    my ( $self, $id, $attr_ref ) = @_;
    my $core = $attr_ref->{core} || die "Need core!";
    
    $core_of{ $id} =  $core;
    my $core_type =
        $core->isa("SElement")    ? "SElement":
        $core->isa("SObject")     ? "SObject" :
        $core->isa("SCat::OfObj") ? "SCat_OfObj":
        $core->isa("SPos")        ? "SPos":
        die "Unknown type: $core";
   $core_type_of{ $id} = $core_type;

}


#### method get_fringe
# description    :The fringe of a thought is other related thoughts. The fringe calculation may depend on the current status of everything.
# argument list  :none
# return type    :A hash ref, keys being fringe items, values being a ref to a two element array, consisting of the key and the activation level (0 to 100)
# context of call:scalar
# exceptions     :

sub get_fringe{
    my $self = shift;
    my $id = ident $self;
    my $type = $core_type_of{$id};
    my $subname = "_get_fringe_$type";
    no strict;
    $subname->( $self, $core_of{ $id });
}


#### method get_extended_fringe
# description    :extended fringe is in some ways a "bigger" fringe, as obtained when a thought is scrutinized too closely.
# argument list  :
# return type    :Same as that of get_fringe()
# context of call:scalar
# exceptions     :

sub get_extended_fringe{
    my $self = shift;
    my $id = ident $self;
    my $type = $core_type_of{$id};
    my $subname = "_get_extended_fringe_$type";
    no strict;
    $subname->( $self, $core_of{ $id });
}


#### method get_actions
# description    :The current thought may call for certain actions to be taken, like launching codelets. This method is how those are found.
# argument list  :
# return type    :ref to an array of actions. Actions have embedded in them their importance
# context of call:scalar
# exceptions     :


sub get_actions{
    my $self = shift;
    my $id = ident $self;
    my $type = $core_type_of{$id};
    my $subname = "_get_actions_$type";
    no strict;
    $subname->( $self, $core_of{ $id });
}

#### _get_*_type Family
### These methods do all the work of the three methods above. Each will be described here for how it works; how it is called can be seen in the methods above.



sub _get_fringe_SObject{
    my ( $thought, $core ) = @_;
}
sub _get_fringe_SCat_OfObj{
    my ( $thought, $core ) = @_;
}
sub _get_fringe_SPos{
    my ( $thought, $core ) = @_;
}

sub _get_extended_fringe_SObject{
    my ( $thought, $core ) = @_;
}

sub _get_extended_fringe_SCat_OfObj{
    my ( $thought, $core ) = @_;
}

sub _get_extended_fringe_SPos{
    my ( $thought, $core ) = @_;
}

sub _get_actions_SObject{
    my ( $thought, $core ) = @_;
}

sub _get_actions_SCat_OfObj{
    my ( $thought, $core ) = @_;
}

sub _get_actions_SPos{
    my ( $thought, $core ) = @_;
}

1;


