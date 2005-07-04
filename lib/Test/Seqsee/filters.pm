package Test::Seqsee::filters;

use Test::Base::Filter -base;

use SBuiltObj;

sub Test::Base::Filter::oddman{
  my ( $self, @data ) = @_;
  my @built_objects = 
    map { 
      SBuiltObj->new_deep( split(/\s+/, $_) ) 
    } @data;
  # print "Oddman filter: data = '", join("'\n---\n'", @built_objects), "'\n";
  return scalar( SUtil::oddman(@built_objects) );
}


1;
