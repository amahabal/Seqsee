package SCat::literal;
use Carp;

my %Memoize;

my $builder = sub {
    my ( $self, $args_ref ) = @_;
    my $structure = $args_ref->{structure};
    defined($structure) or croak "need structure";

    my $string = scat_literal_as_string($structure);
    return $Memoize{$string} if exists $Memoize{$string};

    my $prototype = SObject->create( $structure );
    my $builder_of_new = sub {
        # my ( $me, $my_args_ref ) = @_;
        return SObject->create( $prototype );
    };
    my $empty_ok = ( !( ref $structure ) or @$structure ) ? 0 : 1;
    my $ret_cat = SCat::OfObj->new(
        {   name     => $string,
            builder  => $builder_of_new,
            to_guess => [],
            att_type => {},
            empty_ok => $empty_ok,
        }
    );
    return ( $Memoize{$string} = $ret_cat );
};

our $literal = SCat::OfCat->new(
    {  
        name       => "literal",
        builder    => $builder,
        empty_ok   => 0,
    }
);

#$literal->compose();

sub scat_literal_as_string {
    my $structure = shift;
    if ( ref $structure ) {
        return "[ "
            . join( ", ", map { scat_literal_as_string($_) } @$structure )
            . " ]";
    }
    else {
        return $structure;
    }
}

1;
