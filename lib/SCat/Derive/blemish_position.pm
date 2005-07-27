package SCat;
use strict;
use Carp;

sub derive_blemish_position {
    my ( $self, $pos ) = @_;
    UNIVERSAL::isa( $pos, "SPos" ) or croak "need SPos";
    my $name = $self->get_name()
        . " containing a blemish at position "
        . $pos->get_name;
    my $new_cat = new SCat(
        {   name       => $name,
            attributes => [ $self->get_att()->members ],
            builder    => sub {
                confess "builder for $name should not have been called!\n";
            },
            instancer => sub {
                shift;
                my $built_obj = shift;
                my $bindings  = $self->is_instance($built_obj);
                return unless $bindings;
                my $where = $bindings->get_where()->[0];
                my $range;

                #print "In blemish_position instancer..\n";
                #print "\twhere is $where\n";
                eval { $range = $pos->find_range($built_obj) };
                if ($@) {
                    print "Died here! Reason: $@\n";
                    return;
                }
                if ($range) {

                    #print "\trange is @$range\n";
                    return $range->[0] == $where
                        ? $bindings
                        : undef;

                }
                else {

                    #print "\tno range!\n";
                    return undef;
                }
            },

        }

    );
}

1;
