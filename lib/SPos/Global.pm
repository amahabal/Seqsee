package SPos::Global;
use base 'SPos';

use Perl6::Subs;
use Perl6::Attributes;

method new($package: +$finder of SPosFinder is required){
  my $self = bless {}, $package;
  $.finder = $finder;
  $self;
}

method find_range($built_obj){
  $.finder->find_range($built_obj);
}

1;
