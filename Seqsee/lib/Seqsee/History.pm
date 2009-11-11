use MooseX::Declare;
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

  method BUILD() {
    $self->dob($Global::Steps_Finished);
    $self->_insert_messages( _history_string("created") );
  }

  sub _history_string {
    my ($msg) = @_;
    my $steps = $Global::Steps_Finished || 0;
    return "[$steps]$Global::CurrentRunnableString\t$msg";
  }

  method AddHistory($msg) {
    $self->_insert_messages(_history_string($msg));
  }

  method search_history($re) {
    return
    map { m/^ \[ (\d+) \]/ox; $1 } ( grep $re, @{ $self->messages } );
  }

  method UnchangedSince(Int $since) {
    my $last_msg_str = $self->message(-1);
    $last_msg_str =~ /^ \[ (\d+) \]/ox or confess "Huh '$last_msg_str'";
    return $1 > $since ? 0 :1;
  }

  method GetAge() {
    return $Global::Steps_Finished - $self->dob;
  }

  method history_as_text() {
    return join( "\n", "History:", @{ $self->messages } );
  }

};
