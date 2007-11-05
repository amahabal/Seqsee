package SCat::literal;
use Carp;

my %Memoize;

my $builder = sub {
    my ( $self, $args_ref ) = @_;
    my $structure = $args_ref->{structure};
    defined($structure) or croak "need structure";

    my $prototype   = SObject->create($structure);
    my $string      = scat_literal_as_string( $prototype->get_structure );
    my $to_recreate = qq{\$S::LITERAL->build({ structure => '$string'})};
    return $Memoize{$string} if exists $Memoize{$string};

    my $builder_of_new = sub {

        # my ( $me, $my_args_ref ) = @_;
        return SObject->create($prototype);
    };
    my $empty_ok = ( !( ref $structure ) or @$structure ) ? 0 : 1;
    my $ret_cat = SCat::OfObj::Std->new(
        {   name        => $string,
            to_recreate => $to_recreate,
            builder     => $builder_of_new,
            to_guess    => [],
            att_type    => {},
            empty_ok    => $empty_ok,
        }
    );
    return ( $Memoize{$string} = $ret_cat );
};

our $literal = SCat::OfCat->new(
    {   name        => q{literal},
        to_recreate => q{$S::LITERAL},
        builder     => $builder,
        empty_ok    => 0,
    }
);

#$literal->compose();

sub scat_literal_as_string {
    my $structure = shift;
    if ( ref $structure ) {
        return "[ " . join( ", ", map { scat_literal_as_string($_) } @$structure ) . " ]";
    }
    else {
        return $structure;
    }
}

1;
