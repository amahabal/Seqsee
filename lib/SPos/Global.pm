package SPos::Global;
use base 'SPos';

use Perl6::Subs;
#use MyFilter;

method new($package: +$finder of SPosFinder is required){
  my $self = bless {}, $package;
  $self->{finder} = $finder;
  $self;
}

method find_range($built_obj){
  $self->{finder}->find_range($built_obj);
}

1;
