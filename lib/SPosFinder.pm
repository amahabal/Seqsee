package SPosFinder;
use strict;
use SErr;
use Carp;

use Class::Std;
my %multi_of :ATTR;
my %sub_of :ATTR;

sub BUILD{
  my ( $self, $id, $options_ref ) = @_;
  $multi_of{$id} = $options_ref->{multi};
  $sub_of{$id}   = $options_ref->{sub};
  defined($multi_of{$id}) or croak "need multi!";
  UNIVERSAL::isa($sub_of{$id}, "CODE") or croak "sub better be sub!";
}

sub find_range {
  my ( $self, $built_obj ) = @_;
  my $id = ident $self;
  my $range = $sub_of{$id}->($built_obj);
  if ( @$range > 1 ) {
    SErr::Pos::UnExpMulti->throw( error => "found multiple matches: @$range" )
      unless $multi_of{$id};
  }
  $range;
}

1;
