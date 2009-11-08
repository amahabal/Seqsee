{

package SCF::CheckIfInstance;
our $package_name_ = 'SCF::CheckIfInstance';
our $NAME = 'Check Whether Object is an Instance of this Category';

        use 5.10.0;
        use strict;
        use Carp;
        use Smart::Comments;
        use English qw(-no_match_vars);
        use SCF;
        
        use Class::Multimethods;
        multimethod 'FindTransform';
        multimethod 'ApplyTransform';



sub run{
    my ( $action_object, $opts_ref ) = @_;
    	my $obj = $opts_ref->{obj} // confess "Needed 'obj', only got " . join(';', keys %$opts_ref);
	my $cat = $opts_ref->{cat} // confess "Needed 'cat', only got " . join(';', keys %$opts_ref);

    
        if ( $obj->describe_as($cat) ) {
            if ( $Global::Feature{LTM} ) {
                SLTM::SpikeBy( 10, $cat );
                SLTM::InsertISALink( $obj, $cat )->Spike(5);
            }
        }
    
}
 # end run


1;
} # end surrounding




{

package SCF::AttemptExtensionOfGroup;
our $package_name_ = 'SCF::AttemptExtensionOfGroup';
our $NAME = 'Attempt Extension of Group';

        use 5.10.0;
        use strict;
        use Carp;
        use Smart::Comments;
        use English qw(-no_match_vars);
        use SCF;
        
        use Class::Multimethods;
        multimethod 'FindTransform';
        multimethod 'ApplyTransform';


        multimethod 'SanityCheck';
    

sub run{
    my ( $action_object, $opts_ref ) = @_;
    	my $object = $opts_ref->{object} // confess "Needed 'object', only got " . join(';', keys %$opts_ref);
	my $direction = $opts_ref->{direction} // confess "Needed 'direction', only got " . join(';', keys %$opts_ref);

    SWorkspace::__CheckLiveness($object) or return;
        my $underlying_reln = $object->get_underlying_reln();
        if ($underlying_reln) {
            SanityCheck( $object, $underlying_reln, "In AttemptExtensionOfGroup pre" );
        }
        my $extension = $object->FindExtension($direction, 0) or return;
        if ($underlying_reln) {
            SanityCheck( $object, $underlying_reln, "In AttemptExtensionOfGroup post" );
        }

        #print STDERR "\nExtending object: ", $object->as_text();
        #print STDERR "\nExtension found:", $extension->as_text();
        #print STDERR "\nDirection:", $direction;
        #main::message("Found extension: $extension; " . $extension->get_structure_string());
        my $add_to_end_p = ( $direction eq $object->get_direction() ) ? 1 : 0;
        ## add_to_end_p (in SCF): $add_to_end_p
        my $extend_success;
        
       eval { 
            $extend_success = $object->Extend( $extension, $add_to_end_p );
         };
       if (my $err = $EVAL_ERROR) {
          CATCH_BLOCK: { if (UNIVERSAL::isa($err, 'SErr::CouldNotCreateExtendedGroup')) { 
                my $msg = "Extending object: " . $object->as_text() . "\n";
                $msg .= "Extension: " . $extension->as_text() . " in direction $add_to_end_p\n";
                print STDERR $msg;
                main::message($msg);
            ; last CATCH_BLOCK; }die $err }
       }
    

        return unless $extend_success;
        if ( SUtil::toss( $object->get_strength() / 100 ) ) {
            SCodelet->new("AreWeDone", 
                         100,
                         { group => $object })->schedule(); 
;
        }
        if ($underlying_reln and not $object->get_underlying_reln) {
            confess "underlying_reln lost!";
        }
        #main::message("Extended!");

    
}
 # end run


    

1;
} # end surrounding




{

package SCF::TryToSquint;
our $package_name_ = 'SCF::TryToSquint';
our $NAME = 'Try to See As';

        use 5.10.0;
        use strict;
        use Carp;
        use Smart::Comments;
        use English qw(-no_match_vars);
        use SCF;
        
        use Class::Multimethods;
        multimethod 'FindTransform';
        multimethod 'ApplyTransform';



    

sub run{
    my ( $action_object, $opts_ref ) = @_;
    	my $actual = $opts_ref->{actual} // confess "Needed 'actual', only got " . join(';', keys %$opts_ref);
	my $intended = $opts_ref->{intended} // confess "Needed 'intended', only got " . join(';', keys %$opts_ref);

    
        # main::message("In TryToSquint");
        my @potential_squints = $actual->CheckSquintability($intended) or return;
        #main::message("potential_squints: @potential_squints");
        my $chosen_squint = SLTM::SpikeAndChoose(100, @potential_squints) or return;
        #main::message("chosen_squint: $chosen_squint");

        my ($cat, $name) = $chosen_squint->GetCatAndName;
        #main::message("CAT/NAME: $cat, $name");
        $actual->AnnotateWithMetonym( $cat, $name );
        $actual->SetMetonymActiveness(1);

    
}
 # end run


    

1;
} # end surrounding




{

package SCF::ConvulseEnd;
our $package_name_ = 'SCF::ConvulseEnd';
our $NAME = 'Shake Group Boundries';

        use 5.10.0;
        use strict;
        use Carp;
        use Smart::Comments;
        use English qw(-no_match_vars);
        use SCF;
        
        use Class::Multimethods;
        multimethod 'FindTransform';
        multimethod 'ApplyTransform';



    

sub run{
    my ( $action_object, $opts_ref ) = @_;
    	my $object = $opts_ref->{object} // confess "Needed 'object', only got " . join(';', keys %$opts_ref);
	my $direction = $opts_ref->{direction} // confess "Needed 'direction', only got " . join(';', keys %$opts_ref);

    
        unless ( SWorkspace::__CheckLiveness($object) ) {
            return;    # main::message("SCF::ConvulseEnd: " . $object->as_text());
        }
        my $change_at_end_p = ( $direction eq $object->get_direction() ) ? 1 : 0;
        my @object_parts = @$object;
        my $ejected_object;
        if ($change_at_end_p) {
            $ejected_object = pop(@object_parts);
        }
        else {
            $ejected_object = shift(@object_parts);
        }

        my $underlying_reln = $object->get_underlying_reln();
        multimethod 'SanityCheck';
        if ($underlying_reln) {
            SanityCheck( $object, $underlying_reln, "Pre-extension" );
        }

        my $new_extension = $object->FindExtension( $direction, 1 ) or return;
        if ( my $unstarred = $new_extension->get_is_a_metonym() ) {
            main::message("new_extension was metonym! fixing...");
            $new_extension = $unstarred;
        }
        if ( $new_extension and $new_extension ne $ejected_object ) {
            if ($underlying_reln) {
                SanityCheck( $object, $underlying_reln, "post-extension" );
            }

            my $structure_string_before_ejection = $object->as_text();
            if ($change_at_end_p) {
                $ejected_object = pop(@$object);
            }
            else {
                $ejected_object = shift(@$object);
            }
            SWorkspace::__RemoveFromSupergroups_of( $ejected_object, $object );
            $object->recalculate_edges();

            #main::message( "New extension! Instead of "
            #      . $ejected_object->as_text()
            #      . " I can use "
            #      . $new_extension->as_text() );
            my $extended = eval { $object->Extend( $new_extension, $change_at_end_p ) };
            if ( my $e = $EVAL_ERROR ) {
                if ( UNIVERSAL::isa( $e, "SErr::CouldNotCreateExtendedGroup" ) ) {
                    print STDERR "(structure before ejection): $structure_string_before_ejection\n";
                    print STDERR "Extending group: ", $object->as_text(), "\n";
                    print STDERR "(But effectively): ", $object->GetEffectiveStructureString();
                    print STDERR "Ejected object: ", $ejected_object->get_structure_string(), "\n";
                    print STDERR "(But effectively): ",
                        $ejected_object->GetEffectiveStructureString();
                    print STDERR "New object: ", $new_extension->get_structure_string(), "\n";
                    print STDERR "(But effectively): ",
                        $new_extension->GetEffectiveStructureString();
                    confess "Unable to extend group!";
                }
                confess $e;
            }
            unless ($extended) {

                # main::message("Failed to extend, and no deaths!");
                if ($change_at_end_p) {
                    push( @$object, $ejected_object );
                }
                else {
                    unshift( @$object, $ejected_object );
                }
                $object->recalculate_edges();
            }
        }

    
}
 # end run


    

1;
} # end surrounding




{

package SCF::CheckProgress;
our $package_name_ = 'SCF::CheckProgress';
our $NAME = 'Check Progress';

        use 5.10.0;
        use strict;
        use Carp;
        use Smart::Comments;
        use English qw(-no_match_vars);
        use SCF;
        
        use Class::Multimethods;
        multimethod 'FindTransform';
        multimethod 'ApplyTransform';


        our $last_time_progresschecker_run = 0;
    

sub run{
    my ( $action_object, $opts_ref ) = @_;
    
    
        our $last_time_progresschecker_run;
        my $time_since_last_addn    = $Global::Steps_Finished - $Global::TimeOfNewStructure;
        my $time_since_new_elements = $Global::Steps_Finished - $Global::TimeOfLastNewElement;
        my $time_since_codelet_run  = $Global::Steps_Finished - $last_time_progresschecker_run;

        # Don't run too frequently
        return if $time_since_codelet_run < 100;
        $last_time_progresschecker_run = $Global::Steps_Finished;

        my $desperation = CalculateDesperation( $time_since_last_addn, $time_since_new_elements );

        my $chooser_on_inv_strength = SChoose->create( { map => q{100 - $_->get_strength()} } );
        if ( $desperation > 50 ) {
            main::ask_for_more_terms();
        }
        elsif ( $desperation > 30 ) {

            # XXX(Board-it-up): [2007/02/14] should be biased by 100 - strength?
            # my $gp = SChoose->uniform([SWorkspace::GetGroups()]);
            my $gp = $chooser_on_inv_strength->( [ SWorkspace::GetGroups() ] );
            if ($gp) {

                # main::message("Deleting group $gp: " . $gp->get_structure_string());
                SWorkspace->remove_gp($gp);
            }
        }
        elsif ( $desperation > 10 ) {
            for ( values %SWorkspace::relations ) {
                my $age = $_->GetAge();
                if (    SUtil::toss( ( 100 - $_->get_strength() ) / 200 )
                    and SUtil::toss( $age / 400 ) )
                {
                    $_->uninsert();
                }
            }
        }

    
}
 # end run

        my @Cutoffs = ( [ 1500, 0, 80 ], [ 800, 2500, 80 ], [ 500, 0, 40 ], [ 200, 0, 20 ], );

        sub CalculateDesperation {
            my ( $time_since_last_addn, $time_since_new_elements ) = @_;
            for (@Cutoffs) {
                my ( $a, $b, $c ) = @$_;
                return $c if ( $time_since_last_addn >= $a
                    and $time_since_new_elements >= $b );
            }
            return 0;
        }
    

1;
} # end surrounding



