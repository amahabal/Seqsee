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
  my $logger = ${"SCF::$self->[0]::logger"} || fishy_codefamily($self->[0]);
  $self->logself($logger) if $logger->is_info();
  &{"SCF::$self->[0]::run"}($self->[3]);
}

sub logself{
  my ($self, $logger) = @_;
  my $str = <<"STR";


($::CurrentEpoch) $::CurrentCodeletFamily

STR

  while (my ($k, $v) = each %{$self->[3]}){
    $str .= join("", "\t$k\t=>", SUtility::pprint($v), "\n");
  }
  $logger->info($str);
}

sub fishy_codefamily{
  my $family = shift;
  print STDERR "[In SCodelet.pm] Problems with family '$family'! Running routine checks:\n";
  unless (exists $INC{"SCF/$family.pm"}) {
    print STDERR "The family $family IS NOT EVEN USED! Do you need to add it to SCF.list? Have you run 'perl Makefile.PL' recently enough?";
    foreach (keys %INC) {
      print "\t$_\n";
    }
    exit;
  }
  unless (defined ${"SCF::$family::logger"}) {
    print STDERR "The variable \$logger not defined in the family\n";
  }
  unless (UNIVERSAL::can("SCF::$family", "run")) {
    print STDERR "The method 'run' not defined in the family!\n";
  }
  exit;
}

1;

