class SObject;

does SHistory;
does SDescs;
does SThought;

has %.bonds;
has %.bonds_p;
has %.groups;
has %.groups_p;

method bond_insert     ($bond)     {...} #No need to override
method bond_promote    ($bond)     {...} #No need to override 
method bond_remove     ($bond)     {...} #No need to override 

method group_insert    ($group)    {...} #No need to override
method group_promote   ($group)    {...} #No need to override 
method group_remove    ($group)    {...} #No need to override 

method halo            ()          {...} #No need to override

method bond_insert($bond){
  if ($bond.build_level == Built::Fully) {
    %.bonds{$bond} = $bond;
  } else {
    %.bonds_p{$bond} = $bond;
  }
}

method bond_promote($bond){...}
method bond_remove($bond){...}

method group_insert($group){...}
method group_remove($group){...}
method group_promote($group) {...}

method halo(){
  .descriptors();
}
