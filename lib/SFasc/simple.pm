# I should hopefully be able to manage things in a way such that I can write a program that will write a .pm file that will do this without several function calls.

package SFasc::simple;

@SElement::FascOrder   = qw{};
@SGroup::FascOrder     = qw{};
@SBond::FascOrder      = qw{};
@SDesc::FascOrder      = qw{};
@SBDesc::FascOrder     = qw{};

$SElement::FascCallBacks = 
  {
  };


$SGroup::FascCallBacks =
  {

  };

$SBond::FascCallBacks = 
  {

  };

$SDesc::FascCallBacks =
  {

  };

$SBDesc::FascCallBacks =
  {

  };


sub SFascination::update_all{
  my $k, $v;
  while ( my($k, $v) = each %SWorkspace::bonds) {
    $v->update_fascinations;
  }
  while ( my($k, $v) = each %SWorkspace::bonds_p) {
    $v->update_fascinations;
  }
  foreach (@SWorkspace::elements) {
    $_->update_fascinations;
  }
  while ( my($k, $v) = each %SWorkspace::groups) {
    $v->update_fascinations;
  }
  while ( my($k, $v) = each %SWorkspace::groups_p) {
    $v->update_fascinations;
  }

}

1;
