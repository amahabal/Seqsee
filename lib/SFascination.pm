package SFascination;
use UNIVERSAL::require;

sub update_fascinations{
  my ($self) = @_;
  my $class = ref($self);
  my $hashref = ${ $class . "::FascCallBacks" };
  foreach my $what (@{ $class . "::FascOrder" }) {
    my $callback = $hashref->{$what};
    $self->{f}{$what} = &{$callback}($self);
  }
}

sub load{
  my $package          = shift;
  my $Fascination_Pack = shift;
  $Fascination_Pack->require;
}


1;

=head1 Usage:

In whatever class that does a C<use SFascination;>, the following must be defined: C<@FascOrder> and C<$FascCallBacks> which is a hashref. In general, all these would be defined in one file for several classes, and this can be loaded by a call to load, like this:

C<< SFascination->load($modulename) >>

where C<$modulename> will be a F<.pm> file including the class definitions.

=cut


1;
