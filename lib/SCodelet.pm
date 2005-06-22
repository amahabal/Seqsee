package SCodelet;
use strict;
use SErr;

sub new{
  my ($package, $family, $urgency, %args) = @_;
  bless [$family, $urgency, $::CurrentEpoch, \%args], $package;
}

sub run{
  my $self = shift;
  $::CurrentCodelet = $self;
  $::CurrentCodeletFamily = $self->[0];
  no strict;
  my $code = *{"SCF::$self->[0]::run"}{CODE} or 
    fishy_codefamily($self->[0]);
  $code->($self->[3]);
}

sub fishy_codefamily{
  my $family = shift;
  unless (exists $INC{"SCF/$family.pm"}) {
    SErr::Code::UnknownFamily->throw("The codefamily $family IS NOT EVEN USED! Do you need to add it to SCF.list? Have you run 'perl Makefile.PL' recently enough?");
  }
  SErr::Code::MalFormed->throw("COuld not find codeobject for family $family. Problem?");
}

1;
