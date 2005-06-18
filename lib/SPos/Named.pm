package SPos::Named;
use Perl6::Subs;
use Perl6::Attributes;
use base 'SPos';

our %Memoize;

method new($package: $str){
  return $Memoize{$str} if $Memoize{$str};
  my $self = bless { }, $package;
  $.find_by_cat = {};
  $Memoize{$str} = $self;
}

method install_finder(+$cat    of SCat       is required, 
		      +$finder of SPosFinder is required){
  $.find_by_cat{$cat} = $finder;
} 

method find_range($built_obj){
  my @cats = $built_obj->get_cats;
  my @matching_cats = grep { exists $.find_by_cat{$_} } @cats;
  return undef unless @matching_cats;
  my @matching_ranges = 
    map { 
      $.find_by_cat{$_}->find_range($built_obj);
    } @matching_cats;
  return $matching_ranges[0] if @matching_ranges == 1;
  # XXX I should check whether the different answers are the same,
  #  but right now I think I'll just throw..
  SErr::Pos::MultipleNamed->throw("$.name for $built_obj");
}


1;
