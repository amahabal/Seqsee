BEGIN {

    package Carp;
    use Carp::Heavy;
    *Carp::format_arg = sub {
        my ($arg) = @_;

        # (Abhijit Mahabal) My addition.
        $arg = SUtil::StringifyForCarp($arg);
        $arg =~ s/'/\\'/g;
        $arg = str_len_trim( $arg, $MaxArgLen );

        # Quote it?
        $arg = "'$arg'" unless $arg =~ /^-?[\d.]+\z/;

        # The following handling of "control chars" is direct from
        # the original code - it is broken on Unicode though.
        # Suggestions?
        #utf8::is_utf8($arg)
        #    or $arg =~ s/([[:cntrl:]]|[[:^ascii:]])/sprintf("\\x{%x}",ord($1))/eg;
        return $arg;
    };

    # Returns a full stack backtrace starting from where it is
    # told.
    *Carp::ret_backtrace = sub {
        my ( $i, @error ) = @_;
        my $mess;
        my $err = join '', @error;
        $i++;

        my $tid_msg = '';
        if ( defined &Thread::tid ) {
            my $tid = Thread->self->tid;
            $tid_msg = " thread $tid" if $tid;
        }

        my %i = caller_info($i);
        $mess = "$err at $i{file} line $i{line}$tid_msg\n";

        while ( my %i = caller_info( ++$i ) ) {
            $mess .= "\n=====\n\t$i{sub_name} called at $i{file} line $i{line}$tid_msg\n";
        }

        return $mess;
    };
    $Carp::MaxEvalLen = 0;
    $Carp::MaxArgLen  = 0;
}

use strict;
use lib 'genlib';
use Getopt::Long;
use Global;
use Test::Seqsee;

my %options = (
    f => sub {
        my ( $ignored, $feature_name ) = @_;
        print "$feature_name will be turned on\n";
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
