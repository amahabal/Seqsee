package SCat;
use strict;
use Carp;

sub derive_blemish_count{
  my ( $self, $count ) = @_;
  my $name = $self->get_name() . " containing $count blemish(es)";
  my $new_cat = new SCat
    ( { name => $name,
	attributes => [ $self->get_att()->members ],
	builder => sub { 
	  confess "builder for $name should not have been called!\n";
	},
	instancer => sub {
	  shift;
	  my $bindings = $self->is_instance(@_);
	  return 
	    scalar( @{ $bindings->get_where } ) == $count 
	      ? $bindings
		: undef;
	},

      }
 
    );
}

1;
