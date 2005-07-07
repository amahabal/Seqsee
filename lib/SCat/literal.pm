package SCat::literal;
use Carp;

my %Memoize;

my $builder = sub {
  my ( $self, $args_ref ) = @_;
  my $structure = $args_ref->{structure} or croak "need structure";
  my $string = scat_literal_as_string($structure);
  return $Memoize{$string} if exists $Memoize{$string};
  my $builder_of_new = sub {
    my ( $me, $my_args_ref ) = @_;
    return SBuiltObj->new_deep(@$structure);
  };
  my $empty_ok = (@$structure) ? 0 : 1;
  my $ret_cat =  SCat->new( {name => $string, 
			     builder => $builder_of_new,
			     empty_ok => $empty_ok,
			    }
		  );
  $ret_cat->compose();
  return ($Memoize{$string} = $ret_cat);
};

our $literal = SCat->new( { attributes => [qw{structure}],
			    builder    => $builder,
			    empty_ok   => 0,
			    }
			   );

#$literal->compose();

sub scat_literal_as_string{
  my $structure = shift;
  if (ref $structure) {
    return "[ " . join(", ", map { scat_literal_as_string($_) 
				 } @$structure) . " ]";
  } else {
    return $structure;
  }
}

1;
