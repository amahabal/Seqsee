package SCF::reader;

our $logger = Log::Log4perl->get_logger("SCF.reader");

sub run{
  my $self = shift;
  my $obj = SWorkspace->object_get( choose => 1,
				    built  => Built::Fully,
				    must   => [$SWorkspace::ReadHead]
				  );
  if ($obj) {
    $logger->info("Read $obj->{str}");
    SStream->new_thought($obj);
    $SWorkspace::ReadHead = $obj->{right_edge} + 1;
    $SWorkspace::ReadHead = $SWorkspace::elements_count - 1
      if $SWorkspace::ReadHead >= $SWorkspace::elements_count;
  }

}

1;
