package SLog;
use Log::Log4perl;

sub init{
  my ($pack, $logging) = @_;
  unless ($logging) {
    Log::Log4perl::init(\"log4perl.logger = FATAL");
    return;
  }
  unless (-e "logger.conf") {
    open OUT, ">logger.conf";
print OUT <<'DEFAULTLOGFILE';
log4perl.logger                  = INFO, file
log4perl.appender.file           = Log::Log4perl::Appender::File
log4perl.appender.file.filename  = logfile
log4perl.appender.file.autoflush = 1
log4perl.appender.file.mode      = write
log4perl.appender.file.layout    = PatternLayout
log4perl.logger.SWorkspace       = FATAL
log4perl.logger.SCF              = INFO
DEFAULTLOGFILE

    close OUT;
  }
  Log::Log4perl::init('logger.conf');
  my $logger = Log::Log4perl->get_logger('');
  $logger->info("Run started at: ", scalar(localtime));
  $logger->info("Input         : ", join(", ", @ARGV));
  $logger->info("Random Seed   : ", $SApp::RandomSeed);
  $logger->info("Maximum Steps : ", $SApp::MaxSteps);

}

1;
 
