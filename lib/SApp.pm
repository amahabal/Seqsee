package SApp;
use UNIVERSAL::require;
use SCodeConfig;

sub post_cc($$@){
  my $who  = shift;
  my $what = shift;
  $CodeConfig::Post{$who}{$what}->(@_);
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
  # XXX something akin to post_cc needed
}

sub process_codefamilies{
  #print STDERR "processing codefamilies\n";
  open(IN, "SCF.list") or die "Could not open codefamily list (SCF.list)";
  while (my $in = <IN>) {
    $in =~ s{#.*}{};
    $in =~ s#\s##g;
    next unless $in;
    $in->require or die "Required Codefamily $in missing";
  }
}

1;
