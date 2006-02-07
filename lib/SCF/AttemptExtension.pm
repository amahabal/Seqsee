#####################################################
#
#    Package: SCF::AttemptExtension
#
# CF: AttemptExtension
#
# Options:
#
# How It Works:
#
# Thought/Codelets Scheduled:
#
#####################################################
#   
#####################################################

package SCF::AttemptExtension;
use strict;
use Carp;
use Smart::Comments;
use English qw(-no_match_vars);

use Class::Multimethods;
multimethod 'find_reln';
multimethod 'apply_reln';
multimethod 'plonk_into_place';
use base qw{};

{
    my ($logger, $is_debug, $is_info);
    BEGIN{ $logger   = Log::Log4perl->get_logger("SCF::AttemptExtension"); 
           $is_debug = $logger->is_debug();
           $is_info  = $logger->is_info();
         }
    sub LOGGING_DEBUG() { $is_debug; }
    sub LOGGING_INFO()  { $is_info;  }
}

my $logger = Log::Log4perl->get_logger("SCF::AttemptExtension"); 


# method: run
# 
#
sub run{
    my ( $action_object, $opts_ref ) = @_;
        if (LOGGING_INFO()) {
        my $msg = $action_object->generate_log_msg();

        $logger->info( $msg );
    }
    ################################
    ## Code above autogenerated.
    ## Insert Code Below
    my $core = $opts_ref->{core} or confess "need core";
    my $direction = $opts_ref->{direction} or confess "need direction";

    my $direction_of_core = $core->get_direction;
    unless ($direction == $direction_of_core) {
        return;
        # XXX unimplemented currently. Needs work.
    }
    
    my $underlying_reln = $core->get_underlying_reln;
    my $core_object_ref = $core->get_parts_ref;
    my $core_span = $core->get_span;
    my $last_object = $core_object_ref->[-1];
    my $what_comes_next = apply_reln( $underlying_reln, $last_object );
    #XXX assuming rightward extension.
    my $current_right_edge = $core->get_right_edge;
    
    # Check that this is what is present...
    my $is_this_what_is_present;
    #main::message("AttemptExtension of ". $core->as_text);
    eval {$is_this_what_is_present= 
              SWorkspace->check_at_location({ start => $current_right_edge + 1,
                                              direction => $direction,
                                              what => $what_comes_next,
                                          }
                                                );
      };
    if ($EVAL_ERROR) {
        my $err = $EVAL_ERROR;
        #main::message("Good! Error caught");
        if (UNIVERSAL::isa($err, "SErr::AskUser")) {
            my $already_matched = $err->already_matched();
            my $ask_if_what = $err->next_elements();
            #main::message("already_matched @$already_matched; span = $core_span");
            if (worth_asking($already_matched, $ask_if_what, $core_span)) {
                # main::message("We may ask the user if the next elements are: @$ask_if_what");
                my $ans = main::ask_user($ask_if_what);
                if ($ans) {
                    SWorkspace->insert_elements( @$ask_if_what );
                } else {
                    $core->set_right_extendibility(-1);
                }
            } else {
                #main::message("decided not to ask if next are @$ask_if_what");
            }
            return;
        } else {
            $err->rethrow;
        }
    }
    if ($is_this_what_is_present) {
        my $wso = plonk_into_place($current_right_edge + $direction, 
                                   $direction,
                                   $what_comes_next
                                       );
        my $reln = find_reln( $last_object, $wso);
        $last_object->add_reln( $reln, 1 );
        $wso->add_reln( $reln, 1);
        SWorkspace->add_reln($reln);
        push @$core_object_ref, $wso;
        $core->recalculate_edges();
        # main::message("Okay, extended");
    } else {
        # main::message("Hmmm.. could not extend. Strange.");
    }

}

sub worth_asking{
    my ( $matched, $unmatched, $extension_from_span ) = @_;
    ## $matched
    ## $unmatched
    my $penetration = (scalar(@$matched) + $extension_from_span) / $SWorkspace::elements_count;
    ## $penetration
    return unless $penetration;

    my $on_a_limb = scalar(@$unmatched)/(scalar(@$matched) + $extension_from_span);
    return 1 if ($penetration > 0.3 and $on_a_limb < 0.8);
    return;
}

1;
