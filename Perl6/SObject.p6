role SInstance {
    has  %.cats;
    method add_category(: $cat, $bindings ) {...}
    method remove_category(: $cat) {...}
    methods get_categories() {...}
    methods is_of_category_p(:$cat) {...}
    methods GetBindingForCategory(:$cat) {...}
    methods get_common_categories(: SInstance $o2) {...}
}

class SObject does SInstance does SHistory does SFasc {
    has                 @.items    of SObject;
    has bool            $.group_p;
    
    has SMetonym        $.metonym;
    has bool            $.metonym_activeness;
    has SObject         $.is_a_metonym_of;

    has Direction       $.direction;
    has RelationScheme  $.reln_scheme;

    has                 %.reln_other;
    has SRuleApp        $.underlying_reln;
}

class SAnchored is SObject {
    has int $.left_edge;
    has int $.right_edge;
}

class SElement is SAnchored {
    has int $.mag;
}

