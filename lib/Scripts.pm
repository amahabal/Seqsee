package Scripts;
use 5.010;
use Moose;
use English qw( -no_match_vars );
use Carp;
use Smart::Comments;

use Exception::Class (
  'SErr::ScriptReturn' => {},
  'SErr::CallSubscript' => {fields => ['name', 'arguments']},
);

sub RETURN {
  print "RETURN\n";
  SErr::ScriptReturn->throw();
}

sub SCRIPT {
  my ($name, $arguments) = @_;
  print "SCRIPT($name)\n";
  SErr::CallSubscript->throw(name => $name, arguments => $arguments);
}

__PACKAGE__->meta->make_immutable;
1;
