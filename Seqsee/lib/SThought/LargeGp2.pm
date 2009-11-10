{

  package SCF::LargeGroup;
  our $package_name_ = 'SCF::LargeGroup';
  our $NAME          = 'I See a Large Group';

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

    my $flush_right = $group->IsFlushRight();
    my $flush_left  = $group->IsFlushLeft();

    if ( $flush_right and $flush_left ) {
      SCodelet->new( "AreWeDone", 100, { group => $group } )->schedule();
    }
    elsif ( $Global::AtLeastOneUserVerification
      and $flush_right
      and!$flush_left )
    {
      SCodelet->new( "MaybeStartBlemish", 100, { group => $group } )
      ->schedule();
    }

  }

  # end run

  1;
}    # end surrounding

{

  package SCF::MaybeStartBlemish;
  our $package_name_ = 'SCF::MaybeStartBlemish';
  our $NAME          = 'Maybe the Sequence Has an Initial Blemish';

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

    #XXX runs too eagerly.
    my $flush_right = $group->IsFlushRight();
    my $flush_left  = $group->IsFlushLeft();
    if ( !$flush_left ) {
      my $extension = $group->FindExtension( $DIR::LEFT, 0 );
      if ($extension) {
        $group->Extend( $extension, 0 );
      }
      else {

        # So there *is* a blemish!
        #main::message("Start Blemish?");
        my $underlying_ruleapp = $group->get_underlying_reln() or return;
        my $underlying_rule    = $underlying_ruleapp->get_rule();
        my $transform          = $underlying_rule->get_transform();

        if ( $transform->isa("Transform::Structural") ) {
          my $cat = $transform->get_category();

          #main::message($cat->get_name());
          if ( $cat->get_name() =~ m#^Interlaced_(.*)#o ) {
            SCodelet->new(
              "InterlacedInitialBlemish",
              100,
              {
                count => $1,
                group => $group,
                cat   => $cat,
              }
            )->schedule();
            return;
          }
        }

        # So: either statecount > 1, or not interlaced.
        if ($flush_right) {
          SCodelet->new( "ArbitraryInitialBlemish", 100, { group => $group } )
          ->schedule();
        }
      }
    }

  }

  # end run

  1;
}    # end surrounding

{

  package SCF::InterlacedInitialBlemish;
  our $package_name_ = 'SCF::InterlacedInitialBlemish';
  our $NAME          = 'One-off Error';

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
    my $count = $opts_ref->{count}
    // confess "Needed 'count', only got " . join( ';', keys %$opts_ref );
    my $group = $opts_ref->{group}
    // confess "Needed 'group', only got " . join( ';', keys %$opts_ref );
    my $cat = $opts_ref->{cat}
    // confess "Needed 'cat', only got " . join( ';', keys %$opts_ref );

    return unless SWorkspace::__CheckLiveness($group);
    my @parts = @$group;
    Global::Hilit( 1, @parts );
    main::message(
      "I realize that there are $count interlaced groups in the sequence, and I have started on the wrong foot. I will shift the big group one unit, and see if that helps!!"
    );
    Global::ClearHilit();
    my @subparts = map { @$_ } @parts;
    SWorkspace::__DeleteGroup($group);
    SWorkspace::__DeleteGroup($_) for @parts;

    # Also delete other interlaced groups of this category.
    for my $object ( SWorkspace::__GetObjectsBelongingToCategory($cat) ) {
      next unless SWorkspace::__CheckLiveness($object);

      # main::message("Shifting, so Deleting " . $object->as_text());
      SWorkspace::__DeleteGroup($object);
    }

    shift(@subparts);
    my @newparts;
    while ( @subparts >= $count ) {
      my @new_part;
      for ( 1 .. $count ) {
        push @new_part, shift(@subparts);
      }
      my $newpart = SAnchored->create(@new_part);
      $newpart->describe_as($cat);
      SWorkspace->add_group($newpart) or return;
      push @newparts, $newpart;
    }
    if ( @newparts > 1 ) {
      my $transform = FindTransform( @newparts[ 0, 1 ] ) or return;
      my $new_gp = SAnchored->create(@newparts);
      $new_gp->describe_as(
        SCat::OfObj::RelationTypeBased->Create($transform) );
      SWorkspace->add_group($new_gp);
      ContinueWith( SThought->create($new_gp) );
    }

  }

  # end run

  1;
}    # end surrounding

{

  package SCF::ArbitraryInitialBlemish;
  our $package_name_ = 'SCF::ArbitraryInitialBlemish';
  our $NAME          = 'A Real Initial Blemish';

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

    SErr::FinishedTestBlemished->throw() if $Global::TestingMode;
    SAction->new(
      {
        family  => "DescribeSolution",
        urgency => 100,
        args    => { group => $group }
      }
    )->conditionally_run();

  }

  # end run

  1;
}    # end surrounding

1;
