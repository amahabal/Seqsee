package SCodelet;
use strict;
use Carp;
use English qw(-no_match_vars);

sub new {
    my ( $package, $family, $urgency, $args_ref ) = @_;
    $args_ref ||= {};
    bless [ $family, $urgency, $Global::Steps_Finished, $args_ref ], $package;
}

sub as_text {
    my ($self) = @_;
    return "Codelet(family=$self->[0],urgency=$self->[1],args="
        . SUtil::StringifyForCarp( $self->[3] );
}

sub run {
    my $self = shift;
    if ($Global::debugMAX) {
        main::message("About to run: " . SUtil::StringifyForCarp($self));
    }
    return unless CheckFreshness( $self->[2], values %{ $self->[3] } );
    $Global::CurrentCodelet       = $self;
    $Global::CurrentCodeletFamily = $self->[0];
    no strict;
    my $code = *{"SCF::$self->[0]::run"}{CODE}
        or fishy_codefamily( $self->[0] );
    eval { $code->( $self, $self->[3] ) };
    if ($EVAL_ERROR) {
        die $EVAL_ERROR if ref($EVAL_ERROR);
        if ($EVAL_ERROR =~ /_TK_EXIT_/) {
            die $EVAL_ERROR;
        }
        if ($EVAL_ERROR =~ /\n=====\n/) {
            # Probably already a confess..
            die("Encountered a confess while running a codelet:\n$EVAL_ERROR");
        } else {
            confess("Encountered C<die> while running a codelet. Family => $self->[0]. Arguments => $self->[3]\n $EVAL_ERROR");
        }
    }
}

sub fishy_codefamily {
    my $family = shift;
    print "fishy_codefamily called: $family!\n";
    unless ( exists $INC{"SCF/$family.pm"} ) {
        SErr::Code->throw(
            "The codefamily $family IS NOT EVEN USED! Do you need to add it to SCF.list? Have you run 'perl Makefile.PL' recently enough?"
        );
    }
    SErr::Code->throw("COuld not find codeobject for family $family. Problem?");
}


# method: schedule
# adds self to Coderack
#
#    Parallels a method in SThought that schedules itself.
sub schedule {
    my ($self) = @_;
    SCoderack->add_codelet($self);
}


sub CheckFreshness {
    my $since = shift;    # Should not have changed since this time.
    for (@_) {
        return unless ( IsFresh( $_, $since ) );
    }
    return 1;
}

use Class::Multimethods;
multimethod IsFresh => ( '*', '#' ) => sub {

    # detualt case:fresh.
    return 1;
};

multimethod IsFresh => ( 'HASH', '#' ) => sub {
    return 1;
};

multimethod IsFresh => ( 'SAnchored', '#' ) => sub {
    my ( $obj, $since ) = @_;
    return $obj->UnchangedSince($since);
};
multimethod IsFresh => ( 'SRelation', '#' ) => sub {
    my ( $rel, $since ) = @_;
    my @ends = $rel->get_ends();
    return ( $ends[0]->UnchangedSince($since) and $ends[1]->UnchangedSince($since) );
};

1;
