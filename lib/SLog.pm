package SLog;
use strict;  
use Log::Log4perl;
use S;
use SUtil;
use List::Util;


## method init
# description    :initializes logging: creates a new file in the subdirectory log/, makes log/latest a symlink to this. 
# argument list  :$package: +$logging, +$sequence, +$seed, +$steps
# return type    :
# context of call:
# exceptions     :

sub init{
    my ( $pack, $opts_ref ) = @_;
    unless (exists $opts_ref->{log}) {
        die "Expected information about whether to log";
    }
    my $logging = $opts_ref->{log} || 0;
    my $sequence = $opts_ref->{seq} || die "Expected to see a sequence";
    my $seed = $opts_ref->{seed} || die "expected to see a seed";
    my $steps = $opts_ref->{max_steps} || die "expected max  steps";

    $sequence = join(", ", @$sequence);

    if ($logging) {
        Log::Log4perl::init("log.conf");
    } else {
        Log::Log4perl::init(\<<'NOLOG');
log4perl.logger                  = FATAL, file

log4perl.appender.file           = Log::Log4perl::Appender::File
log4perl.appender.file.filename  = log/nolog
log4perl.appender.file.autoflush = 1
log4perl.appender.file.mode      = write
log4perl.appender.file.layout    = PatternLayout

NOLOG
    }

    my $logger = Log::Log4perl->get_logger();
    
    if ($logger->is_info()) {
        my $msg = join(q{},
                       "Run started at: ", scalar(localtime), "\n",
                       "Input         : ", $sequence, "\n",
                       "Random Seed   : ", $seed, "\n",
                       "Maximum Steps : ", $steps, "\n",
                       "\n",
                           );
        $logger->info($msg);
    }

    if ($logging) {
        unlink "log/latest";
        system "ln -s $SLog::filename log/latest";
    }
}

1;
