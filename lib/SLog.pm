package SLog;
use strict;  
use Log::Log4perl;
use List::Util;


#### method init
# description    :initializes logging: creates a new file in the subdirectory log/, makes log/latest a symlink to this. 
# argument list  :$package: +$logging, +$sequence, +$seed, +$steps
# return type    :
# context of call:
# exceptions     :

sub init{
    my ( $pack, $opts_ref ) = @_;
    my $logging = $opts_ref->{logging} || 0;
    my $sequence = $opts_ref->{sequence} || [];
    my $seed = $opts_ref->{seed} || 0;
    my $steps = $opts_ref->{steps} || 0;

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
    unlink "log/latest";
    system "ln -s $SLog::filename log/latest";
}

1;
