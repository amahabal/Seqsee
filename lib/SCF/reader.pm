package SCF::reader;
our $logger;

BEGIN{ 
  $logger = Log::Log4perl->get_logger("SCF.reader");
}
use constant LOGGING_DEBUG => $logger->is_debug;
use constant LOGGING_INFO  => $logger->is_info;

sub run{
  my $self = shift;
  my $obj = SWorkspace->object_get( choose => 1,
				    built  => Built::Fully,
				    must   => [$SWorkspace::ReadHead]
				  );
  if ($obj) {
    $logger->info("Read $obj->{str}") if LOGGING_INFO;
    $obj->history_add('Read into stream');
    SStream->new_thought($obj);
    $SWorkspace::ReadHead = $obj->{right_edge} + 1;
    $SWorkspace::ReadHead = $SWorkspace::elements_count - 1
      if $SWorkspace::ReadHead >= $SWorkspace::elements_count;
  }

}

1;
