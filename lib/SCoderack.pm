package SCoderack;
use strict;
use Carp;

our $bucket_count  = 10;
our $urgencies_sum = 0;
our $last_bucket   = $bucket_count - 1;
our $codelet_count = 0;     # Number of codelets in the coderack
our @buckets       = ();
our @bucket_sum    = ();
our $MAX_CODELETS  = 150;   # Maximum number of codelets allowed.

our %FamilyUrgency;
our %FamilyCount;

sub add_codelet{
  my ($package, $codelet ) = @_;
  confess "A non codelet is being added" unless $codelet->isa("SCodelet");
  if ( $codelet_count > $MAX_CODELETS ) {
    my $half_of_avg_urgency = 0.5 * $urgencies_sum / $codelet_count;
    foreach my $b (@buckets) {
      my @new_bucket;
      foreach my $cl (@$b) {
	my $age = $::CurrentEpoch - $cl->[2];
	if ( $age < 50 or $cl->[1] > $half_of_avg_urgency ) {
	  # $cl should be kept!
	  push(@new_bucket, $cl);
	}
      }
      $b = [@new_bucket];
    }
    $urgencies_sum = 0;
    $codelet_count = 0;
    for my $i ( 0 .. $bucket_count - 1 ) {
      my $sum = 0;
      foreach my $cl ( @{ $buckets[$i] } ) {
	$sum           += $cl->[1];
	$codelet_count++;
      }
      $bucket_sum[$i] = $sum;
      $urgencies_sum += $sum;
    }    
  }
  my $urgency = $codelet->[1];
  $codelet->[1] = $urgency = int($urgency);
  return unless $urgency;
  
  $last_bucket = $last_bucket + 1;
  $last_bucket = 0 if ( $last_bucket == $bucket_count );
  push( @{ $buckets[$last_bucket] }, $codelet );
  $urgencies_sum            += $urgency;
  $bucket_sum[$last_bucket] += $urgency;
  $codelet_count++;
  my $family = $codelet->[0];
  $FamilyCount{$family}++;
  $FamilyUrgency{$family} += $urgency;
  $::CODERACK_gui->update() if ::GUI;
}

sub choose_codelet {
  return undef unless $codelet_count;
  confess "In Coderack: urgencies sum 0, but codelet count non-zero"
    unless $urgencies_sum;
  my $random_number = 1 + int( rand($urgencies_sum) );
  my $bucket = 0;
  while ( $random_number > $bucket_sum[$bucket] ) {
    $random_number -= $bucket_sum[$bucket];
    $bucket++;
  }

  my $codelet_position = 0;
  my $urgency;
  while ( ( $urgency = $buckets[$bucket][$codelet_position]->[1] )
    and $random_number > $urgency )
  {
    $random_number -= $urgency;
    $codelet_position++;
  }
  my $return_codelet = splice( @{ $buckets[$bucket] }, $codelet_position, 1 );
  $bucket_sum[$bucket] -= $urgency;
  $urgencies_sum       -= $urgency;
  $codelet_count--;

  unless ( UNIVERSAL::isa( $return_codelet, "SCodelet" ) ) {
    print("############## TROUBLE!\n",
	  "Something not a codelet chosen from the coderack!\n",
	  "Bucket: $bucket; Codelet Position: $codelet_position\n",
	  "urgency: $urgency. Urgency sum: $urgencies_sum\n");
    confess();
  }
  my $family = $return_codelet->[0];
  $FamilyCount{$family}--;
  $FamilyUrgency{$family} -= $urgency;
  $::CODERACK_gui->update() if ::GUI;
  return $return_codelet;
}

sub update_urgency_based_on_age {
  foreach my $b (@buckets) {
    foreach my $cl (@$b) {
      my $age = $::CurrentEpoch - $cl->[2];
      if ( $age >= 5 ) {
        $cl->[1] = int( 1.1 * $cl->[1] );
      }
    }
  }
  $urgencies_sum = 0;
  for my $i ( 0 .. $bucket_count - 1 ) {
    my $sum = 0;
    foreach my $cl ( @{ $buckets[$i] } ) {
      $sum           += $cl->[1];
    }
    $bucket_sum[$i] = $sum;
    $urgencies_sum += $sum;
  }
}

1;
