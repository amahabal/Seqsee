package SCodelet;
use strict;
use Carp;

sub new {
    my ( $package, $family, $urgency, $args_ref ) = @_;
    bless [ $family, $urgency, $::CurrentEpoch, $args_ref ], $package;
}

sub run {
    my $self = shift;
    $::CurrentCodelet       = $self;
    $::CurrentCodeletFamily = $self->[0];
    no strict;
    my $code = *{"SCF::$self->[0]::run"}{CODE}
        or fishy_codefamily( $self->[0] );
    $code->( $self );
}

sub fishy_codefamily {
    my $family = shift;
    unless ( exists $INC{"SCF/$family.pm"} ) {
        SErr::Code::UnknownFamily->throw(
            "The codefamily $family IS NOT EVEN USED! Do you need to add it to SCF.list? Have you run 'perl Makefile.PL' recently enough?"
        );
    }
    SErr::Code::MalFormed->throw(
        "COuld not find codeobject for family $family. Problem?");
}


#### method generate_log_msg
# description    :generates the log message for logging. Called only if it will get logged
# argument list  :
# return type    :
# context of call:called from individual codefamilies
# exceptions     :

sub generate_log_msg{
    my $codelet = shift;
    return 
        join("", "="x10, "\n", 
             "--- (Time: \$::CurrentEpoch; Family: $codelet->[0])\n",);
}

1;
