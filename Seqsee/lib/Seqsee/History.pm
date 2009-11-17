use MooseX::Declare;
use MooseX::AttributeHelpers;
role Seqsee::History {
  has messages => (
    metaclass => 'Collection::Array',
    is        => 'ro',
    isa       => 'ArrayRef[Str]',
    default   => sub { [] },
    provides  => {
      'push'  => '_insert_messages',
      'get'   => 'message',
      'count' => 'message_count',
    }
  );
  has dob => (
    is  => 'rw',
    isa => 'Int',
  );


  sub BUILD {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $opts_ref) = @_;
    $self->dob($Global::Steps_Finished || 0);
    $self->_insert_messages( _history_string("created") );
  }

  sub _history_string {
    my ($msg) = @_;
    my $steps = $Global::Steps_Finished || 0;
    return "[$steps]$Global::CurrentRunnableString\t$msg";
  }


  sub AddHistory {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $msg) = @_;
    $self->_insert_messages(_history_string($msg));
  }


  sub search_history {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $re) = @_;
    return
    map { m/^ \[ (\d+) \]/ox; $1 } ( grep $re, @{ $self->messages } );
  }


  sub UnchangedSince {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $since) = @_;
    my $last_msg_str = $self->message(-1);
    $last_msg_str =~ /^ \[ (\d+) \]/ox or confess "Huh '$last_msg_str'";
    return $1 > $since ? 0 :1;
  }


  sub GetAge {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    return $Global::Steps_Finished - $self->dob;
  }


  sub history_as_text {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    return join( "\n", "History:", @{ $self->messages } );
  }

};
