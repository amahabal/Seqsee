package SCat::OfObj::Test;
use base qw{Test::Class};
use Test::More;
use Test::Deep;

use SObject;
use SCat::OfObj;

sub build1 : Test{
    my $builder = sub { 
        my ( $cat, $opts_ref ) = @_;
        return SObject->create( $opts_ref->{foo},
                                $opts_ref->{bar},
                                $opts_ref->{foo} + 1
                                    );
    };
    my $positions_ref = { bar => SPos->new(2) };
    my $position_finders_ref = 
        { foo => sub 
              { 
                  return [1];
              },
      };
    my $cat = SCat::OfObj->new
        ( 
            
                );
}

1;
