package SCoderack;
use strict;
use Carp;
use Config::Std;
use Smart::Comments;

my $BUCKET_COUNT  = 10;
my $MAX_CODELETS  = 150;                # Maximum number of codelets allowed.
my $urgencies_sum;
my $last_bucket;
my $codelet_count;                  # Number of codelets in the coderack
my @buckets;
my @bucket_sum;


my %FamilyUrgency;
my %FamilyCount;

clear();

#### method clear
# description    :makes it all empty
# argument list  :
# return type    :
# context of call:
# exceptions     :

sub clear{
    $urgencies_sum    = 0;
    $last_bucket      = $BUCKET_COUNT - 1;
    $codelet_count    = 0;
    @buckets          = ();
    @bucket_sum       = ();
    
    %FamilyUrgency    = ();
    %FamilyCount      = ();
}


#### method init
# usage          :Initializes the coderack, using data from the configuarion for codelet types and numbers to use
# description    :
# argument list  :OPTIONS_ref
# return type    :
# context of call:
# exceptions     :error in config

sub init{
    my $package = shift; # $package
    my $OPTIONS_ref = shift;
    # I am not going to use any of the options here, at least for now.
    # Codelet configuarion for startup should be read in from another configuration file config/start_codelets.conf
    # die "This is where I left yesterday";

    read_config 'config/start_codelets.conf' => my %launch_config;
    for my $family (keys %launch_config) {
        next unless $family;
        ## Family: $family
        my $urgencies = $launch_config{$family}{urgency};
        ## $urgencies
        my @urgencies = (ref $urgencies) ? (@$urgencies) : ($urgencies);
        ## @urgencies
        for (@urgencies) {
            # launch!
            $package->add_codelet(
                new SCodelet( $family, $_, {})
                    );
        }
    }
}

sub add_codelet {
    my ( $package, $codelet ) = @_;
    confess "A non codelet is being added" unless $codelet->isa("SCodelet");
    ## Adding codelet to coderack: $codelet
    if ( $codelet_count > $MAX_CODELETS ) {
        my $half_of_avg_urgency = 0.5 * $urgencies_sum / $codelet_count;
        foreach my $b (@buckets) {
            my @new_bucket;
            foreach my $cl (@$b) {
                my $age = $::CurrentEpoch - $cl->[2];
                if ( $age < 50 or $cl->[1] > $half_of_avg_urgency ) {

                    # $cl should be kept!
                    push( @new_bucket, $cl );
                }
            }
            $b = [@new_bucket];
        }
        $urgencies_sum = 0;
        $codelet_count = 0;
        for my $i ( 0 .. $BUCKET_COUNT - 1 ) {
            my $sum = 0;
            foreach my $cl ( @{ $buckets[$i] } ) {
                $sum += $cl->[1];
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
    $last_bucket = 0 if ( $last_bucket == $BUCKET_COUNT );
    push( @{ $buckets[$last_bucket] }, $codelet );
    $urgencies_sum            += $urgency;
    $bucket_sum[$last_bucket] += $urgency;
    $codelet_count++;
    my $family = $codelet->[0];
    $FamilyCount{$family}++;
    $FamilyUrgency{$family} += $urgency;

    # $::CODERACK_gui->Update() if ::GUI();
}

sub choose_codelet {
    return undef unless $codelet_count;
    confess "In Coderack: urgencies sum 0, but codelet count non-zero"
        unless $urgencies_sum;
    my $random_number = 1 + int( rand($urgencies_sum) );
    my $bucket        = 0;
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
    my $return_codelet
        = splice( @{ $buckets[$bucket] }, $codelet_position, 1 );
    $bucket_sum[$bucket] -= $urgency;
    $urgencies_sum       -= $urgency;
    $codelet_count--;

    unless ( UNIVERSAL::isa( $return_codelet, "SCodelet" ) ) {
        print(
            "############## TROUBLE!\n",
            "Something not a codelet chosen from the coderack!\n",
            "Bucket: $bucket; Codelet Position: $codelet_position\n",
            "urgency: $urgency. Urgency sum: $urgencies_sum\n"
        );
        confess();
    }
    my $family = $return_codelet->[0];
    $FamilyCount{$family}--;
    $FamilyUrgency{$family} -= $urgency;

    # $::CODERACK_gui->Update() if ::GUI();
    return $return_codelet;
}

############## ACCESSORS, mostly for testing

sub get_last_bucket { return $last_bucket }
sub get_urgencies_sum { return $urgencies_sum }
sub get_codelet_count { return $codelet_count }

{
    my $buckets_ref = \@buckets;
    my $bucket_sum_ref = \@bucket_sum;

    use Scalar::Util qw(weaken);
    weaken( $buckets_ref );
    weaken( $bucket_sum_ref );

    sub get_buckets { return $buckets_ref }
    sub get_bucket_sum { return $bucket_sum_ref }
}

1;
