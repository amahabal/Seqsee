class SWorkspace;

our @.elements;
our $.elements_count;
our %.bonds;
our %.bonds_p;
our %.groups;
our %.groups_p;

our $.ReadHead;

method setup          (Int @elems) {...}
method insert_elements(Int @elems) {...}

method element_choose (+$chooser = $SChooser::NULL){
  $chooser.choose_safe( @.elements );
}

method bond_insert ($bond){...}
method bond_remove ($bond){...}
method bond_promote($bond){...}
method bond_get( +$built, +$from, +$to, +@filters, +$choose, +$chooser ){
  ...
}

method group_insert ($group){...}
method group_remove ($group){...}
method group_promote($group){...}
method group_get(*%options){...} # same as to object_get
method group_choose(*%options){...}

method object_get(+$built=(Built::Fully|Built::Partly), 
		  +$type, +@must, +@must_not, 
		  +$choose, +$chooser = $SChooser::NULL) {...}

