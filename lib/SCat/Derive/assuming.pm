package SCat;
use strict;

sub derive_assuming{
  my ($self, @rest) = @_;
  my %assuming = @rest;
  my $new_cat = new SCat
    ({ attributes => [],
       builder => sub{
	 shift;
	 my $opts = shift;
	 $self->build({ %assuming, %$opts });
       },
       instancer => sub {
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
       },
       empty_ok => $self->get_empty_ok,
       guesser_pos_of => {}, # not needed
       guesser_of => {}, #not needed

     });
 
  $new_cat->set_att ($self->get_att - (new Set::Scalar(keys %assuming)));

  $new_cat;
  
}

1;
