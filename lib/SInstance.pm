package SInstance;

use Perl6::Attributes;
use Perl6::Subs;
use SCat;

method add_cat(SCat $cat, *%bindings){
  foreach (keys %bindings) {
    die "Category $cat does not take the attribute $_" unless
      $cat->has_attribute($_);
  }
  $SCat::Str2Cat{$cat} = $cat;
  $.cats{$cat} = \%bindings;
  $self;
} 

method get_cat_bindings(SCat $cat){
  return undef unless exists $.cats{$cat};
  $.cats{$cat};
}

method get_cats(){
  map { $SCat::Str2Cat{$_} } keys %.cats;
}

method get_blemish_cats(){
  my %ret;
  while (my ($k, $binding) = each %.cats) {
    if ($SCat::Str2Cat{$k}->is_blemished_cat) {
      $ret{$k} = $binding->{what};
    }
  }
  \%ret;
}

method instance_of_cat(SCat $cat){
  exists $.cats{$cat};
}



1;
