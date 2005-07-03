package SUtil;
use strict;
use SPos;
use SCat;
use SBlemish;
use Carp;

our @EXPORT = qw{uniq equal_when_flattened generate_blemished};
our @ISA    = qw{Exporter};

sub uniq {
  my %hash;
  for (@_) {
    $hash{$_} = $_;
  }
  values %hash;
}

sub compare_deep{
  (@_ == 2) or confess;
  my ( $deep_list1, $deep_list2 ) = @_;
  my $is_ref1 = ref $deep_list1;
  my $is_ref2 = ref $deep_list2;
  if (!$is_ref1 and !$is_ref2) {
    return ( $deep_list1 == $deep_list2 );
  }
  if ($is_ref1 and $is_ref2) {
    return unless @$deep_list1 == @$deep_list2;
    for (my $i=0; $i<@$deep_list1; $i++) {
      return unless compare_deep($deep_list1->[$i],
				 $deep_list2->[$i]
				);
    }
    return 1;
  }
  return;
}

sub equal_when_flattened {
  my ( $obj1, $obj2 ) = @_;
  unless ( ref $obj1 ) {
    if ( ref $obj2 ) {
      return undef;
    }
    else {
      return $obj1 == $obj2;
    }
  }
  return undef unless ref $obj2;
  my @flattened1 = $obj1->flatten;
  my @flattened2 = $obj2->flatten;
  return undef unless scalar(@flattened1) == scalar(@flattened2);
  for my $i ( 0 .. scalar(@flattened1) - 1 ) {
    return undef unless $flattened1[$i] == $flattened2[$i];
  }
  return 1;
}

sub generate_blemished {
  my ( %args ) = @_;
  my $cat       = delete $args{cat};
  my $blemish   = delete $args{blemish};
  my $pos       = delete $args{pos};
  my $bo        = $cat->build({ %args });
  my $blemished = $bo->apply_blemish_at( $blemish, $pos );
  return $blemished;
}

1;
