package SPosFinder;
use SErr;
use Perl6::Subs;
use Perl6::Attributes;

method new($package: +$multi is required, +$sub of Code is required ){
  my $self = bless {}, $package;
  $.multi = $multi;
  $.sub   = $sub;
  $self;
}

method find_range($built_obj){
  my $range = $.sub->($built_obj);
  if (@$range > 1) {
    SErr::Pos::UnExpMulti->throw(error => "found multiple matches: @$range")
	unless $.multi;
  }
  $range;
}

1;
