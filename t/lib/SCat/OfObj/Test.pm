package SCat::OfObj::Test;
use base qw{Test::Class};
use Test::More;
use Test::Deep;

use S;
use SObject;
use SCat::OfObj;

use Smart::Comments;

sub create : Test(startup => 1){
    my $builder = sub { 
        my ( $cat, $opts_ref ) = @_;
        ## Builder args: $opts_ref
        return SObject->create( $opts_ref->{foo},
                                $opts_ref->{bar},
                                $opts_ref->{foo} + 1
                                    );
    };
    my $positions_ref = { bar => SPos->new(2) };
    my $position_finders_ref = 
        { foo => sub 
              { 
                  return [0];
              },
      };
    my $description_finder_ref =
        { bat => sub {
              my ( $object ) = @_;
              
              
          },
      };
    my $cat = SCat::OfObj->new
        ( {name => "test_cat",
           builder => $builder,
           to_guess => [qw/foo bar/],
           positions => $positions_ref,
           position_finders => $position_finders_ref,
       }
              );
    isa_ok($cat, "SCat::OfObj");
    shift->{cat} = $cat;
}

sub build :Test(1){
    my $cat = shift->{cat};
    my $object = $cat->build({ foo => 1, bar => 3});
    $object->structure_ok([1,3,2]);
}

sub is_instance :Test(2){
    my $cat = shift->{cat};
    my $object = SObject->create(2,7,3);
    my $bindings = $cat->is_instance($object);
    ok($bindings);

    $object = SObject->create(2,7,4);
    $bindings = $cat->is_instance( $object );
    ok(!$bindings);

}



1;
