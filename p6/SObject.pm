class SObject;

does SHistory;
does SDescs;
is   SThought;

has %.bonds;
has %.bonds_p;
has %.groups;
has %.groups_p;

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

