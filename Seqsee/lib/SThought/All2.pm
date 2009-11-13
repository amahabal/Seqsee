{

  package SCF::AreRelated;
  our $package_name_ = 'SCF::AreRelated';
  our $NAME          = 'Are These Two Objects Related?';

  use 5.10.0;
  use strict;
  use Carp;
  use Smart::Comments;
  use English qw(-no_match_vars);
  use SCF;

  use Class::Multimethods;
  multimethod 'FindTransform';
  multimethod 'ApplyTransform';

  sub run {
    my ( $action_object, $opts_ref ) = @_;
    my $a = $opts_ref->{a}
    // confess "Needed 'a', only got " . join( ';', keys %$opts_ref );
    my $b = $opts_ref->{b}
    // confess "Needed 'b', only got " . join( ';', keys %$opts_ref );

    my $a_core = $a->can('get_core') ? $a->get_core() :undef;
    my $b_core = $b->can('get_core') ? $b->get_core() :undef;

    ## $a_core, $b_core

    if ( $a_core and $b_core ) {
      if ( $a_core->isa("Seqsee::Object") and $b_core->isa("Seqsee::Object") ) {
        SAction->new(
          {
            family  => "FindIfRelated",
            urgency => 100,
            args    => {
              a => $a_core,
              b => $b_core
            }
          }
        )->conditionally_run();
      }
      elsif ( $a_core->isa("SRelation") and $b_core->isa("SRelation") ) {
        ## I am comparing two relations!
        SAction->new(
          {
            family  => "FindIfRelatedRelations",
            urgency => 100,
            args    => {
              a => $a_core,
              b => $b_core
            }
          }
        )->conditionally_run();
      }
    }

  }

  # end run

  1;
}    # end surrounding

{

  package SCF::AreTheseGroupable;
  our $package_name_ = 'SCF::AreTheseGroupable';
  our $NAME          = 'Can These Objects be Grouped?';

  use 5.10.0;
  use strict;
  use Carp;
  use Smart::Comments;
  use English qw(-no_match_vars);
  use SCF;

  use Class::Multimethods;
  multimethod 'FindTransform';
  multimethod 'ApplyTransform';

  sub run {
    my ( $action_object, $opts_ref ) = @_;
    my $items = $opts_ref->{items}
    // confess "Needed 'items', only got " . join( ';', keys %$opts_ref );
    my $reln = $opts_ref->{reln}
    // confess "Needed 'reln', only got " . join( ';', keys %$opts_ref );

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

        eval { $new_group->set_underlying_ruleapp($reln); };
        if ( my $err = $EVAL_ERROR ) {
          CATCH_BLOCK: {
            if ( UNIVERSAL::isa( $err, 'SErr::UnderlyingRelnUnapplicable' ) ) {
              return;
              last CATCH_BLOCK;
            }
            die $err;
          }
        }

        SWorkspace->add_group($new_group);
        my $reln_type = $reln->get_type();
        if ( $reln_type->isa('Transform::Structural')
          or $reln_type->get_category() ne $S::NUMBER )
        {
          $new_group->describe_as(
            SCat::OfObj::RelationTypeBased->Create($reln_type) )
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

  # end run

  1;
}    # end surrounding

{

  package SCF::AreWeDone;
  our $package_name_ = 'SCF::AreWeDone';
  our $NAME          = 'Am I Near the Solution?';

  use 5.10.0;
  use strict;
  use Carp;
  use Smart::Comments;
  use English qw(-no_match_vars);
  use SCF;

  use Class::Multimethods;
  multimethod 'FindTransform';
  multimethod 'ApplyTransform';

  sub run {
    my ( $action_object, $opts_ref ) = @_;
    my $group = $opts_ref->{group}
    // confess "Needed 'group', only got " . join( ';', keys %$opts_ref );

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
          SAction->new(
            {
              family  => "AttemptExtensionOfGroup",
              urgency => 80,
              args    => {
                object    => $gp,
                direction => DIR::RIGHT()
              }
            }
          )->conditionally_run();
        }
      }
    }

  }

  # end run
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
    SAction->new(
      {
        family  => "DescribeSolution",
        urgency => 100,
        args    => { group => $group }
      }
    )->conditionally_run();
  }

  1;
}    # end surrounding

1;
