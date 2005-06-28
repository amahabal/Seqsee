package SPosFinder;
use strict;
use SErr;

sub new{
  my ($package, %options) = @_;
  exists $options{multi} or die;
  my $multi = $options{multi};
  my $sub   = $options{sub}   or die;
  UNIVERSAL::isa($sub, "CODE") or die;
  my $self = bless {}, $package;
  $self->{multi} = $multi;
  $self->{sub}   = $sub;
  $self;
}

sub find_range{
  my ( $self, $built_obj ) = @_;
  my $range = $self->{sub}->($built_obj);
  if (@$range > 1) {
    SErr::Pos::UnExpMulti->throw(error => "found multiple matches: @$range")
	unless $self->{multi};
  }
  $range;
}

1;
