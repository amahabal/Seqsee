package Test::Seqsee::filters;

use Test::Base::Filter -base;

use SBuiltObj;

sub Test::Base::Filter::oddman{
  my ( $self, @data ) = @_;
  my @built_objects = 
    map { 
      my @parts = split /\s+/, $_;
      my @chunked = SUtil::naive_brittle_chunking([@parts]);
      SBuiltObj->new_deep( @chunked ) 
    } @data;
  # print "Oddman filter: data = '", join("'\n---\n'", @built_objects), "'\n";
  return scalar( SUtil::oddman(@built_objects) );
}


1;
