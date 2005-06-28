package SPosFinder;
use SErr;
use Perl6::Subs;
# use MyFilter;

method new($package: +$multi is required, +$sub of Code is required ){
  my $self = bless {}, $package;
  $self->{multi} = $multi;
  $self->{sub}   = $sub;
  $self;
}

method find_range($built_obj){
  my $range = $self->{sub}->($built_obj);
  if (@$range > 1) {
    SErr::Pos::UnExpMulti->throw(error => "found multiple matches: @$range")
	unless $self->{multi};
  }
  $range;
}

1;
