use strict;
use blib;

use Config::Std;
use Getopt::Long;

use S;
use SUtil;

use Smart::Comments;

my %DEFAULTS 
    = ( seed => int( rand() * 32000 ),

            );

my $OPTIONS_ref = _read_config_and_commandline();
SLog->init( $OPTIONS_ref );


#### method _read_config_and_commandline
# usage          :
# description    :Reads the configuration (conf/seqsee.conf), updates what it sees using the commandline arguments, sets defaults, and returns the whole thing in a HASH
# argument list  :
# return type    :
# context of call:
# exceptions     :

sub _read_config_and_commandline{
    my $RETURN_ref = {};
    read_config 'config/seqsee.conf' => my %config;
    my %options;
    GetOptions( \%options,
                "seed=i",
                "log!",
                "tk!",
                "seq=s",
                    );
    for (qw{seed log tk seq max_steps}) {
        my $val 
            = exists($options{$_})        ? $options{$_} :
              exists($config{seqsee}{$_}) ? $config{seqsee}{$_} :
              exists($DEFAULTS{$_})       ? $DEFAULTS{$_} :
                  die "Option '$_' not set either on command line, conf file or defauls";
        $RETURN_ref->{$_} = $val;
    }

    # CHECKING
    my $seq = $RETURN_ref->{seq};
    unless ($seq =~ /^[\d\s]+$/) {
        die "The option --seq must be a space separated list of integers";
    }
    for ($seq) { s/^\s*//; s/\s*$//; }
    my @seq = split(/\s+/, $seq);
    $RETURN_ref->{seq} = [ @seq ];
    return $RETURN_ref;
}
