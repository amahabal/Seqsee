package SCodelet;
use strict;
use Carp;

sub new {
    my ( $package, $family, $urgency, $args_ref ) = @_;
    $args_ref ||= {};
    bless [ $family, $urgency, $Global::Steps_Finished, $args_ref ], $package;
}

sub run {
    my $self = shift;
    return unless CheckFreshness($self->[2], values %{$self->[3]});
    $Global::CurrentCodelet       = $self;
    $Global::CurrentCodeletFamily = $self->[0];
    no strict;
    my $code = *{"SCF::$self->[0]::run"}{CODE}
        or fishy_codefamily( $self->[0] );
    $code->( $self, $self->[3] );
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

#### method generate_log_msg
# description    :generates the log message for logging. Called only if it will get logged
# argument list  :
# return type    :
# context of call:called from individual codefamilies
# exceptions     :

sub generate_log_msg {
    return '' if $Global::TestingMode;
    my $codelet = shift;
    my $ret = join( "", "\n=== $Global::Steps_Finished ", "=" x 10, "  CODELET $codelet->[0] \n" );
    while ( my ( $k, $v ) = each %{ $codelet->[3] } ) {
        $ret .= "== $k \t--> $v\n";
    }
    return $ret;
}

# method: schedule
# adds self to Coderack
#
#    Parallels a method in SThought that schedules itself.
sub schedule {
    my ($self) = @_;
    SCoderack->add_codelet($self);
}

sub display_self {
    my ( $self, $widget ) = @_;
    $widget->Display(
        "Codelet", ["heading"], "\n",
        "\tFamily:\t",  $self->[0], "\n",
        "\tUrgency:\t", $self->[1], "\n",
        "\tArguments:\t\n",
        map { ( "\t\t", $_, "\t=>", $self->[3]{$_} ) }
            ( keys %{ $self->[3] } ),
    );
}


sub CheckFreshness{
    my $since = shift; # Should not have changed since this time.
    for (@_) {
        return unless(IsFresh($_, $since));
    }
    return 1;
}


use Class::Multimethods;
multimethod IsFresh => ('*', '#') => sub {
    # detualt case:fresh.
    return 1;    
};


multimethod IsFresh => ('SAnchored', '#') => sub {
    my ( $obj, $since ) = @_;
    return $obj->UnchangedSince($since);   
};
multimethod IsFresh => ('SReln', '#') => sub {
    my ( $rel, $since ) = @_;
    my @ends = $rel->get_ends();
    return ( $ends[0]->UnchangedSince($since) and $ends[1]->UnchangedSince($since));   
};

1;
