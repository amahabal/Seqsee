package SCat;

sub derive_blemished{
  my ($self, %options) = @_;
  my $blemish = $options{blemish} or die "Must provide a blemish";
  my $position = $options{position} or die "Must provide a position";
  die "Blemish must be a SBlemish" unless UNIVERSAL::isa($blemish, "SBlemish");
  die "Position must be a SPos" unless UNIVERSAL::isa($position, "SPos");
 

  my $new_cat = new SCat
    ({ builder =>  sub {
	 shift;
	 my $bo = $self->build(@_);
	 return $bo->apply_blemish_at($blemish, $position);
       },
       instancer => sub {
	 die "unimplemented";
       },
       empty_ok => 0,
       guesser_pos_of => {},
       guesser_of => {},
       
     });
  $new_cat;
}

1;
