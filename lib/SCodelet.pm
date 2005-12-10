package SCodelet;
use strict;
use Carp;

sub new {
    my ( $package, $family, $urgency, $args_ref ) = @_;
    $args_ref ||= {};
    bless [ $family, $urgency, $::CurrentEpoch, $args_ref ], $package;
}

sub run {
    my $self = shift;
    $::CurrentCodelet       = $self;
    $::CurrentCodeletFamily = $self->[0];
    no strict;
    my $code = *{"SCF::$self->[0]::run"}{CODE}
        or fishy_codefamily( $self->[0] );
    $code->( $self, $self->[3] );
}

sub fishy_codefamily {
    my $family = shift;
    unless ( exists $INC{"SCF/$family.pm"} ) {
        SErr::Code->throw(
            "The codefamily $family IS NOT EVEN USED! Do you need to add it to SCF.list? Have you run 'perl Makefile.PL' recently enough?"
        );
    }
    SErr::Code->throw(
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
    my $ret =         join("", "\n=== $::Steps_Finished ", 
             "="x10, "  CODELET $codelet->[0] \n");
    while (my($k, $v) = each %{$codelet->[3]}) {
        $ret.= "== $k \t--> $v\n";
    }
    return $ret;
}



# method: schedule
# adds self to Coderack
#
#    Parallels a method in SThought that schedules itself.
sub schedule{
    my ( $self ) = @_;
    SCoderack->add_codelet( $self );
}

sub display_self{
    my ( $self, $widget ) = @_;
    $widget->Display("Codelet", ["heading"], "\n", 
                     "\tFamily:\t", $self->[0], "\n",
                     "\tUrgency:\t", $self->[1], "\n",
                     "\tArguments:\t\n",
                     map { ("\t\t", $_, "\t=>", $self->[3]{$_}) } 
                         (keys %{$self->[3]}),
                         );
}



1;
