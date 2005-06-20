package SCat;
use strict;

sub derive_assuming{
  my ($self, @rest) = @_;
  my %assuming = @rest;
  my $new_cat = new SCat;
 
  $new_cat->{att} = $self->{att} - (new Set::Scalar(keys %assuming));
  $new_cat->{builder} = sub{
    shift;
    $self->build(%assuming, @_);
  };
  $new_cat->{instancer} = sub {
    shift;
    my %assuming = %assuming;
    my $bindings = $self->is_instance(@_);
    #print "In instancer. Got bindings $bindings; start is $bindings->{start}\n";
    #print "\t\tend is $bindings->{end}\n";
    return undef unless $bindings;
	#print "assuming is:", %assuming, "\n";
    while (my ($k, $v) = each %assuming) {
      return undef unless $bindings->{$k} eq $v;
      #print "\t assumption $k = $v held up!\n";
    }
    return $bindings;
  };

  $new_cat;
  
}

1;
