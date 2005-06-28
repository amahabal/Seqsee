package SPos::Named;
use strict;
use base 'SPos';

our %Memoize;

sub new{
  my ( $package, $str ) = @_;
  return $Memoize{$str} if $Memoize{$str};
  my $self = bless { }, $package;
  $self->{find_by_cat} = {};
  $self->{name} = $str;
  $Memoize{$str} = $self;
}

sub install_finder{
  my ( $self, %opts ) = @_;
  my $cat = delete $opts{cat};
  my $finder = delete $opts{finder};
  $self->{find_by_cat}{$cat} = $finder;
} 

sub find_range{
  my ( $self, $built_obj ) = @_;
  my @cats = $built_obj->get_cats;
  my @matching_cats = grep { exists $self->{find_by_cat}{$_} } @cats;
  return undef unless @matching_cats;
  my @matching_ranges = 
    map { 
      $self->{find_by_cat}{$_}->find_range($built_obj);
    } @matching_cats;
  return $matching_ranges[0] if @matching_ranges == 1;
  # XXX I should check whether the different answers are the same,
  #  but right now I think I'll just throw..
  SErr::Pos::MultipleNamed->throw("$self->{name} for $built_obj");
}


1;
