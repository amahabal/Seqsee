package SApp;
use UNIVERSAL::require;
use SCodeConfig;

our $RandomSeed = undef;
our $MaxSteps   = 10;

sub post_cc($$@){
  my $who  = shift;
  my $what = shift;
  my $code = $CodeConfig::Post{$who}{$what};
  die "Am trying to do a post_cc, where '$who' is trying to post a '$what', and no configuration information exists as to how that is to happen. Perhaps you need to modify SCodeConfig.txt?" unless $code;
  $code->(@_);
}

our $_codefamilies_processed = 0;

sub init{
  my $package = shift;
  process_codefamilies() unless $_codefamilies_processed;
  $_codefamilies_processed = 1;
  SWorkspace->setup(@_);
  post_cc "StartUp", "all";
}

sub hooks_before_each_step{

}

sub hooks_after_each_step{
  post_cc "Background", "all";
}

sub process_codefamilies{
  #print STDERR "processing codefamilies\n";
  open(IN, "SCF.list") or die "Could not open codefamily list (SCF.list)";
  while (my $in = <IN>) {
    $in =~ s{#.*}{};
    $in =~ s#\s##g;
    next unless $in;
    $in->require or die "Required Codefamily '$in' missing.";

    unless (defined ${"$in"."::logger"}) {
      die"Error in processing codefamily '$in': It defines no variable \$logger\n";
    }

    unless (UNIVERSAL::can($in, "run")) {
      die"Error in processing codefamily '$in': It does not define the method run()";
    }
  }
}

1;
