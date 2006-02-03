#####################################################
#
#    Package: SChoose
#
#####################################################
#   Creating custom choosers
#####################################################

package SChoose;
use strict;
use Carp;
use Class::Std;
use base qw{};

use List::Util qw(sum);


# method: create
# Creates a chooser, returns a sub ref
#
sub create{
    my ( $package, $opts_ref ) = @_;
    {
        my $map_fn = $opts_ref->{map};
        my $map_needed = $map_fn ? 1 : 0;

        my $grep_fn = $opts_ref->{grep};
        my $grep_needed = $grep_fn ? 1 : 0;
        
        my $grep_count = $grep_needed ? 0 : 1;

        return sub {
            my ( $objects_ref ) = @_;
            return unless @$objects_ref;

            my (@likelihood_sums, $likelihood_partial_sum);

            if ($map_needed) {
                for my $obj (@$objects_ref) {
                    my $likelihood;
                    if ($grep_needed and !($grep_fn->($obj))){
                        $likelihood = 0;
                    } else {
                        $likelihood = $map_fn->($obj);
                        $grep_count++;
                    }
                    $likelihood_partial_sum += $likelihood;
                    push @likelihood_sums, 
                        $likelihood_partial_sum;
                }
            } else {
                # no map needed, could still need grep.
                if ($grep_needed) {
                    for my $obj (@$objects_ref) {
                        my $likelihood;
                        if ($grep_fn->($obj)) {
                            $likelihood = $obj;
                            $grep_count++;
                        } else {
                            $likelihood = 0;
                        }
                        $likelihood_partial_sum += $likelihood;
                        push @likelihood_sums, 
                            $likelihood_partial_sum;
                    }
                } else {
                    # neither map, nor grep needed!
                    for my $obj (@$objects_ref) {
                        my $likelihood = $obj;
                        $likelihood_partial_sum += $likelihood;
                        push @likelihood_sums, 
                            $likelihood_partial_sum;
                    }
                }
            }

            unless ($grep_count) { # nothing passed the grep!
                return;
            }
            
            my $idx;
            if ($likelihood_partial_sum) {
                my $random = rand() * $likelihood_partial_sum;
                $idx = -1;
                for (@likelihood_sums) {
                    $idx++;
                    last if $_ >= $random;
                }
            } else {
                $idx = int( rand() * scalar(@likelihood_sums));
            }
            return $objects_ref->[$idx];
        }; 
    }
}



# method: choose
# 
#
sub choose{
    my ( $package, $number_ref, $name_ref ) = @_;
    return unless @$number_ref;
    $name_ref ||= $number_ref;

    my $random = rand() * sum(@$number_ref); 
    my $idx = -1;
    for (@$number_ref) {
        $idx++;
        last if $_ > $random;
        $random -= $_;
    }
    return $name_ref->[$idx];
}

sub using_fascination{
    my ( $package, $array_ref, $fasc ) = @_;
    my @imp = map{ $_->get_fascination($fasc) } @$array_ref;
    $package->choose($array_ref, \@imp);
}


1;
