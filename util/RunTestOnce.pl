use 5.10.0;
use strict;
use lib 'genlib';
use Carp::Seqsee;
use Getopt::Long;
use Global;
use Test::Seqsee;

my %options = (
    f => sub {
        my ( $ignored, $feature_name ) = @_;
        print "$feature_name WILL BE TURNED ON IN THIS SINGLE TEST\n";
        unless ( $Global::PossibleFeatures{$feature_name} ) {
            print "No feature $feature_name. Typo?\n";
            exit;
        }
        $Global::Feature{$feature_name} = 1;
    }
);

GetOptions( \%options, "seq=s", "max_steps=i", "continuation=s", 'f=s', 'max_false=i',
    'min_extension=i', );
for (qw{seq continuation max_false min_extension max_steps}) {
    confess "Missing required argument >>$_<<" unless exists $options{$_};
}

my ( $seq, $continuation, $max_steps, $max_false, $min_extension )
    = @options{qw{seq continuation max_steps max_false min_extension}};
SUtil::trim( $seq, $continuation );
confess unless ( $seq and $continuation and $max_steps);
my @seq          = split( /\s+/, $seq );
my @continuation = split( /\s+/, $continuation );

my $result = RunSeqsee(\@seq, \@continuation, $max_steps, $max_false, $min_extension);
use Storable;
open my $OUT, '>', 'foo';
print {$OUT} Storable::freeze($result);
close $OUT;
