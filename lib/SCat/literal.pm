package SCat::literal;
use Carp;

my $builder = sub {
  my ( $self, $args_ref ) = @_;
  my $structure = $args_ref->{structure} or croak "need structure";
  my $builder_of_new = sub {
    my ( $me, $my_args_ref ) = @_;
    return SBuiltObj->new_deep(@$structure);
  };
  my $empty_ok = (@$structure) ? 0 : 1;
  my $ret_cat =  SCat->new( { builder => $builder_of_new,
			      empty_ok => $empty_ok,
			    }
		  );
  $ret_cat->compose();
  return $ret_cat;
};

our $literal = SCat->new( { attributes => [qw{structure}],
			    builder    => $builder,
			    empty_ok   => 0,
			    }
			   );

#$literal->compose();

1;
