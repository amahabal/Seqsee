class SApp;

our $*MaxSteps = 10;

submethod post_cc($who, $what, *@arguments){...}

my $codefamilies_processed = false;

method init(@input_seq){
  process_codefamilies() unless $codefamilies_processed;
  $codefamilies_processed = true;
  SWorkspace.setup(@input_seq);
  post_cc "StartUp", "all";
}

method hooks_before_each_step(){
  
}

method hooks_after_each_step() {
  post_cc "Background", "all";
}

sub    process_codefamilies(){...}
