package SCodelet;
use strict;
use Log::Log4perl;

our $logger = Log::Log4perl->get_logger('SCF');

sub new{
  my ($package, $family, $urgency, %args) = @_;
  bless [$family, $urgency, $::CurrentEpoch, \%args], $package;
}

sub run{
  my $self = shift;
  $::CurrentCodelet = $self;
  $::CurrentCodeletFamily = $self->[0];
  #XXX Probably need checking for freshness of this codelet
  no strict;
  my $logger = ${"SCF::$self->[0]::logger"};
  $self->logself($logger) if $logger->is_info();
  &{"SCF::$self->[0]::run"}($self->[3]);
}

sub logself{
  my ($self, $logger) = @_;
  my $str = <<"STR";


($::CurrentEpoch) $::CurrentCodeletFamily

STR

  while (my ($k, $v) = each %{$self->[3]}){
    $str .= "\t$k\t=>$v\n";
  }
  $logger->info($str);
}

1;

