package SWorkspace;
use strict;

use SChooser;
use Sconsts;
use SElement;

our $elements_count;
our @elements = ();
our %bonds    = ();
our %bonds_p  = ();
our %groups   = ();
our %groups_p = ();

our $ReadHead = 0;

sub setup{
  my $package = shift;
  %bonds    = ();
  %bonds_p  = ();
  %groups   = ();
  %groups_p = ();
  @elements = ();
  $elements_count = 0;
  SWorkspace->insert_elements(@_);
}

#######################
## Elements

sub insert_elements{
  my $package = shift;
  for (@_) {
    push(@elements, (ref($_) and $_->isa("SElement"))? $_ : SElement->new($_));
    $elements[-1]->{left_edge} = $elements[-1]->{right_edge} = $elements_count;
    $elements_count++;
  }
}

sub element_choose{
  my $package = shift;
  my %options = @_;
  my $chooser = $options{chooser} || $SChooser::NULL;
  return $chooser->choose_safe( @elements );
}

##################### BOND RELATED
sub bond_insert{
  my ($package, $bond) = @_;
  if ($bond->{build_level} == Built::Fully) {
    $bonds{$bond} = $bond;
  } else {
    $bonds_p{$bond} = $bond;
  }
  print "Bond insert into the workspace\n";
  $main::WS_gui->GUI_add($bond) if ::GUI;
}

sub bond_remove{
  my ($package, $bond) = @_;
  delete $bonds{$bond};
  delete $bonds_p{$bond};
}

sub bond_promote{
  my ($package, $bond) = @_;
  delete $bonds_p{$bond};
  $bonds{$bond} = $bond;
}

sub bond_get{
  my $package = shift;
  my %options = @_;
  my $built   = $options{built} || (Built::Partly | Built::Fully);
  my @ret;
  push (@ret, values %bonds )   if ($built & Built::Fully);
  push (@ret, values %bonds_p ) if ($built & Built::Partly);

  if (exists $options{from}) {
    my $from = $options{from};
    #XXX See how I can use grep to speed up
    @ret = grep { $_->{from} = $from } @ret; 
  }

  if (exists $options{to}) {
    my $to = $options{to};
    #XXX See how I can use grep to speed up
    @ret = grep { $_->{to} = $to } @ret; 
  }

  if (exists $options{filters}) {
    #XXX See how I can use grep to speed up
    foreach my $filter ( @{ $options{filters} } ) {
      @ret = grep { &$filter($_) } @ret; 
    }
  }

  if (defined $options{choose}) {
    my $chooser = $options{chooser} || $SChooser::NULL; #XXX? By strength?
    return $chooser->choose_safe( @ret );
  }

  @ret;

}

##################### GROUP RELATED
sub group_insert{
  my ($package, $group) = @_;
  if ($group->{build_level} == Built::Fully) {
    $groups{$group} = $group;
  } else {
    $groups_p{$group} = $group;
  }
}

sub group_remove{
  my ($package, $group) = @_;
  delete $groups{$group};
  delete $groups_p{$group};
}

sub group_promote{
  my ($package, $group) = @_;
  delete $groups_p{$group};
  $groups{$group} = $group;
}

sub group_get{
  my $package = shift;
  $package->object_get( @_, type => "SGroup" );
}

sub group_choose{
  my $package = shift;
  return $package->object_get( @_, type => "SGroup", choose => 1 );
}

############## 
### OBJECT RELATED

sub object_get{
  my $package = shift;
  my %options = @_;
  my $built   = $options{built} || (Built::Partly | Built::Fully);

  my @ret;
  push(@ret, @elements, values %groups)   if ($built & Built::Fully);
  push(@ret,            values %groups_p) if ($built & Built::Partly);

  if (exists $options{type}) {
    my $type = $options{type};
    @ret = grep { $_->isa($type) } @ret;
  }

  if (exists $options{must}) {
    foreach my $pt (@{ $options{must} }) {
      @ret = grep { $_->{left_edge}  <= $pt and
		    $_->{right_edge} >= $pt 
		  } @ret;
    }
  }

  if (exists $options{must_not}) {
    foreach my $pt (@{ $options{must_not} }) {
      @ret = grep { $_->{left_edge}  > $pt or
		    $_->{right_edge} < $pt 
		  } @ret;
    }
  }

  if (defined $options{choose}) {
    my $chooser = $options{chooser} || $SChooser::NULL; #XXX? By strength?
    return $chooser->choose_safe( @ret );
  }

  @ret;
}



1;
