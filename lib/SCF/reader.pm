package SCF::reader;

our $logger = Log::Log4perl->get_logger("SCF.reader");

sub run{
  my $self = shift;
  my $obj = SWorkspace->object_get( choose => 1,
				    built  => Built::Fully,
				    must   => [$SWorkspace::ReadHead]
				  );
}

1;
