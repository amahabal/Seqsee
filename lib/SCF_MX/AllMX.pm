package SCF::CheckIfInstance;
use 5.010;
use MooseX::SCF;
Codelet_Family CheckIfInstance => (
  attributes => [ obj => {}, cat => {} ],
  body       => sub {
    my ( $obj, $cat ) = @_;
    if ( $obj->describe_as($cat) and $Global::Feature{LTM} ) {
      SLTM::SpikeBy( 10, $cat );
      SLTM::InsertISALink( $obj, $cat )->Spike(5);
    }
  }
);

package SCF::FocusOn;
use MooseX::SCF;
use SCF;
Codelet_Family FocusOn => (
  attributes => [ what => { optional => 1 } ],
  body => sub {
   my ($what) = @_;
   if ($what) {
       ContinueWith( SThought->create($what) );
   }

   # Equivalent to Reader
   if ( SUtil::toss(0.1) ) {
       SWorkspace::__CreateSamenessGroupAround($SWorkspace::ReadHead);
       return;
   }
   my $object = SWorkspace::__ReadObjectOrRelation() // return;
   main::message("Focusing on: ".$object->as_text()) if $Global::debugMAX;
   ContinueWith( SThought->create($object) );
  }                           
);
1;
