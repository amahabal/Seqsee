#####################################################
#
#    Package: SCat::OfObj
#
#####################################################
#   Categories whose instances are objects
#
#   This package implements categories whose instances are Objects. Examples of such categories include Ascending, descending, sameness and mountain, plus, of course their derivatives.
#
#####################################################
#
# Positions:
#  These categories have the concept of positions defined for them.

# multi: is_instance ( SCat::OfObj, SBuiltObj )
#  for object categories
#
#    This works as follows for base categories. A potential unblemished version is guessed, and the two are checked for being the same.
# 
#     Most derived categories would just use the instancer of their base categories, and do its extra magic at the end, mostly by playing with the returned SBindings object.
#
#    usage:
#     
#
#    parameter list:
#
#    return value:
#      An SBindings object
#
#    possible exceptions:
#        SErr::Think


