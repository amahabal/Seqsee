class SCoderack;

our $.bucket_count  = 10;
our $.urgencies_sum = 0;
our $.last_bucket   = $.bucket_count - 1;
our $.codelet_count = 0;
our @.buckets       = ();
our @.bucket_sum    = ();
our $.MAX_CODELETS  = 150;

method add_codelet(SCodelet $codelet){
  if $.codelet_count > $.MAX_CODELETS {
     ...  
  }
    ...
}

