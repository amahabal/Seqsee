#####################################################
#
#    Package: SCat::OfRel
#
#####################################################
#   Categories whose instances are relations
#    
#   This package implements categories like successor and predecessor, as also sameness. Plus, of course, their constrained versions, derivatives etc.
#####################################################



# multi: is_instance ( SCat::OfRel, SRel )
# for reln categories
#
#    For the basic categories, it probably works like so: The relation provides the two objects C<first> and C<second>. For all the categories that the two share, it is checked how the bindings of the two object for the categories change, and if that change can be expressed by this category.
#     
#    I must be more explicit. Consider the two objects to be '1 2 3' and '2 3 4'. Let the category be "successor group". Then the bindings of the two objects include first and last: both of which can be looked at as a successor, and this overall relation can then be of successor. *How* it is a successor can be spelled out in the SBindings object returned, and thus more specific subcategories of the relation can be applied. Need to figure out what the SBinding looks like. 
#     
#    A lot more thought needs to go into this still
#
#    usage:
#     
#
#    parameter list:
#
#    return value:
#      SBinding object
#
#    possible exceptions:
#        SErr::Think

