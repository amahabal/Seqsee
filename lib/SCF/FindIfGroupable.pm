#####################################################
# Package: SCF::FindIfGroupable
#
# CF: FindIfGroupable
#
# Options:
# 
# How It Works:
#
# Thought/Codelets Scheduled: 
#   
#####################################################

package SCF::FindIfGroupable;
use strict;
use Carp;
use Class::Std;
use English qw(-no_match_vars);
use List::Util qw(sum);
use Smart::Comments;

use base qw{};

{
    my ($logger, $is_debug, $is_info);
    BEGIN{ $logger   = Log::Log4perl->get_logger("SCF::FindIfGroupable"); 
           $is_debug = $logger->is_debug();
           $is_info  = $logger->is_info();
         }
    sub LOGGING_DEBUG() { $is_debug; }
    sub LOGGING_INFO()  { $is_info;  }
}

my $logger = Log::Log4perl->get_logger("SCF::FindIfGroupable"); 


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
    my $category  = $opts_ref->{category} or confess "Need category";
    my $items_ref = $opts_ref->{items} or confess "Need items";


    my $object;
    # We'll check if all items are anchored
    # Look at the items: all or none should be SAnchored
    my @anchored_p = map { UNIVERSAL::isa($_, "SAnchored") ?1:0} @$items_ref;
    my $anchored_count = sum(@anchored_p);

    ### Got here in FindIfGroupable

    if ($anchored_count == scalar( @anchored_p ) ) {
        $object = SAnchored->create( @$items_ref );
    } elsif (!$anchored_count) { # none anchored
        $object = SObject->new({ items   => $items_ref,
                                    group_p => 1,
                                });
    } else {
        # some anchored, some unanchored
        SErr->throw( "There are some unanchored and some anchored objects that were passed to me. There is a serious flaw somewhere" );
    }

    ### Object created: $object

    my $bindings;
    eval { $bindings = $category->is_instance( $object ); };
    if ($EVAL_ERROR) {
        # is_instance blew up; If it blew up with 
        my $e = $EVAL_ERROR;
        if (UNIVERSAL::isa($e, 'SErr::NeedMoreData')) {
            my $payload = $e->payload(); #can be codelet or thought
            $payload->schedule();
            return;
        } else {
            die $e;
        }
    }

    ### Bindings: $bindings

    return unless $bindings;

    SCodelet->new("FindIfMetonyable", 50)->schedule();
    SThought->create( $object )->schedule();

}
1;
