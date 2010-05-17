package SCF::CheckIfInstance;
use 5.010;
use MooseX::SCF;
Codelet_Family(
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
Codelet_Family(
  attributes => [ what => { optional => 1 } ],
  body       => sub {
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
    main::message( "Focusing on: " . $object->as_text() ) if $Global::debugMAX;
    ContinueWith( SThought->create($object) );
  }
);

package SCF::AreRelated;
use MooseX::SCF;
use English qw(-no_match_vars);
use SCF;
Codelet_Family(
  attributes => [ a => {}, b => {} ],
  body       => sub {
    my ( $a, $b ) = @_;
    my $a_core = $a->can('core') ? $a->core() :undef;
    my $b_core = $b->can('core') ? $b->core() :undef;

    ## $a_core, $b_core

    if ( $a_core and $b_core ) {
      if ( $a_core->isa("SObject") and $b_core->isa("SObject") ) {
        ACTION(
          100,
          FindIfRelated => {
            a => $a_core,
            b => $b_core
          }
        );
      }
      elsif ( $a_core->isa("SRelation") and $b_core->isa("SRelation") ) {
        ## I am comparing two relations!
        ACTION(
          100,
          FindIfRelatedRelations => {
            a => $a_core,
            b => $b_core
          }
        );
      }
    }
  }
);

package SCF::AreTheseGroupable;
use MooseX::SCF;
use English qw(-no_match_vars);
use SCF;

Codelet_Family(
  attributes => [ items => {}, reln => {} ],
  body       => sub {
    my ( $items, $reln ) = @_;

    # Check if these are already grouped...
    # to do that, we need to find the left and right edges
    my ( @left_edges, @right_edges );

    for (@$items) {
      SWorkspace::__CheckLiveness($_) or return;
      push @left_edges,  $_->get_left_edge;
      push @right_edges, $_->get_right_edge;
    }
    my $left_edge  = List::Util::min(@left_edges);
    my $right_edge = List::Util::max(@right_edges);
    my $is_covering =
    scalar( SWorkspace::__GetObjectsWithEndsBeyond( $left_edge, $right_edge ) );
    return if $is_covering;

    my $new_group;
    eval {
      my @unstarred_items = map { $_->GetUnstarred() } @$items;
      ### require: SWorkspace::__CheckLivenessAtSomePoint(@unstarred_items)
      SWorkspace::__CheckLiveness(@unstarred_items) or return;   # dead objects.
      $new_group = SAnchored->create(@unstarred_items);
      if ($new_group) {
        TRY { $new_group->set_underlying_ruleapp($reln); }
        CATCH {
          UnderlyingRelnUnapplicable: {
            return;
          }
        }
        SWorkspace->add_group($new_group);
        my $reln_type = $reln->get_type();
        if ( $reln_type->isa('Transform::Structural')
          or $reln_type->get_category() ne $S::NUMBER )
        {
          $new_group->describe_as(
            SCategory::TransformBased->Create($reln_type) )
          || main::message( "Unable to describe "
            . $new_group->as_text()
            . "  as based on "
            . $reln_type->as_text );
        }
        else {
          state $map = {
            same => $S::SAMENESS,
            succ => $S::ASCENDING,
            pred => $S::DESCENDING
          };
          $new_group->describe_as( $map->{ $reln_type->get_name() }
            || confess "Should not be here ($reln_type)" );
        }
      }

    };
    if ( my $e = $EVAL_ERROR ) {
      if ( UNIVERSAL::isa( $e, "SErr::HolesHere" ) ) {
        return;
      }
      elsif ( UNIVERSAL::isa( $e, 'SErr::ConflictingGroups' ) ) {
        return;
      }
      print "HERE IN SCF::AreTheseGroupable, error is $e of type ", ref($e),
      "\n";
      confess $e;
    }

# confess "@SWorkspace::OBJECTS New group created: $new_group, and added it to w/s";

  }
);

package SCF::AreWeDone;
use MooseX::SCF;
use English qw(-no_match_vars);
use SCF;

my $LastSolutionDescriptionTime;

sub BelieveDone {
  my ($group) = @_;
  if ($Global::TestingMode) {

    # Currently assume belief always right.
    SErr::FinishedTest->new( got_it => 1 )->throw();
  }
  return
  if (  $LastSolutionDescriptionTime
    and $LastSolutionDescriptionTime > $Global::TimeOfLastNewElement );

  $LastSolutionDescriptionTime = $Global::Steps_Finished;
  main::message( "I believe I got it", 1 );
  ACTION( 100, DescribeSolution => { group => $group } );
}

Codelet_Family(
  attributes => [ group => {} ],
  body       => sub {
    my ($group)     = @_;
    my $gp          = $group;
    my $span        = $gp->get_span;
    my $total_count = $SWorkspace::ElementCount;
    my $left_edge   = $gp->get_left_edge();
    ## $span, $total_count
    #main::message( $right_extendibility);

    my $underlying_rule_app = $gp->get_underlying_reln();

    if ( $span / $total_count > 0.5 ) {
      Global::SetRuleAppAsRecent($underlying_rule_app) if $underlying_rule_app;
    }

    if ( $Global::AtLeastOneUserVerification
      and ( $span / $total_count ) > 0.8 )
    {
      if ( $left_edge == 0 ) {
        if ( $span == $total_count ) {

          #Bingo!
          Global::ClearHilit();
          Global::Hilit( 2, @$gp );
          main::update_display();
          BelieveDone($group);
        }
        else {
          ACTION(
            80,
            AttemptExtensionOfGroup => {
              object    => $gp,
              direction => DIR::RIGHT()
            }
          );
        }
      }
    }

  }
);

1;
