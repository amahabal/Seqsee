#####################################################
#
#    Package: SHistory
#
#####################################################
#####################################################

package SHistory;
use strict;
use Carp;
use Class::Std;
use base qw{};

my %messages_of : ATTR( :get<history>);
my %message_count_of : ATTR();

$Global::Steps_Finished        ||= '';
$Global::CurrentRunnableString ||= '';

sub BUILD {
    my ( $self, $id, $opts ) = @_;
    $messages_of{$id} = [ history_string("created") ];
}

sub history_string {
    my ($msg) = @_;
    return "[$Global::Steps_Finished]$Global::CurrentRunnableString\t$msg";
}

sub add_history {
    my ( $self, $msg ) = @_;
    my $id = ident $self;
    push @{ $messages_of{$id} }, history_string($msg);
    $message_count_of{$id}++;
}

sub search_history {
    my ( $self, $re ) = @_;
    return map { m/^ \[ (\d+) \]/o; $1 } (grep $re,
      @{ $messages_of{ ident $self} });
}

1;

