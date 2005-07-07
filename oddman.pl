use blib;
use strict;
use Carp;
use S;
use SUtil;

our @cats = ( $S::ascending, $S::descending, $S::mountain );
our @blemishes = ( $S::double, $S::triple, $S::ntimes );

loop();

sub loop {
  MAIN: while (1) {
    print "Enter the sequence fragments, one per line. Separate each element therein by a space. End by a solitary . on a line by itself. Type done now if you want to stop.\n";
    my @input = ();
    my $in;
    while ( 1 ) {
      $in = <STDIN>;
      chomp($in);
      if ($in =~ /done/i) {
	last MAIN;
      } 
      if ($in =~ /^\s*\.\s*$/ ) {
	process(@input);
	last;
      }
      $in =~ s/^\s*//;
      $in =~ s/\s+$//;
      $in =~ /\S/ or next;
      push @input, [ split(/\s+/, $in) ];
    }
  }
}

sub process{
  my (@input) = @_;
  print "I got ", scalar( @input ), " elements to process\n";
  my @objects = 
    map { SBuiltObj->new_deep( 
			      SUtil::naive_brittle_chunking($_) 
			     ) 
	} @input;
  $_->seek_blemishes(\@blemishes) for @objects;
  my $ret = oddman_both( \@objects );
  print "\n\nSorry, no dice!\n\n" unless $ret;
  print "\n\n";
}

sub oddman_both{
  my $ret = oddman_categorical(@_, \@cats);
  return $ret;
}

sub SCat::generate_secondary_blemish_cats{
  my ( $self, $obj_ref, $bindings_ref ) = @_;

  # Number of blemishes is a first try...
  my @num_blemishes = map { scalar ( @{ $_->get_where } ) 
			  } @$bindings_ref;
  my $oddness = find_odd( @num_blemishes );
  if ( $oddness ) {
    my $new_cat = 
      $self->derive_blemish_count( $oddness->{repeated_value} );
    return ( $new_cat );
  }

  # Okay, so num_blemishes cannot be used to distinguish...
  # Now I require that all the blemishes are at least the same!
  # XXX that is not quite accurate: for a blemish like double all 3s, the number of blemishes may be vastly different
  @num_blemishes = uniq(@num_blemishes);
  return () unless @num_blemishes == 1;
  
  # Excellent. Now I can try the position of the blemishes!
  # I'll further assume that I need there to be a single blemish.
  return () unless $num_blemishes[0] == 1;
 
  my $object_count = scalar( @$obj_ref );

  # Lets try "forward positions", now!
  #print "FORWARD:\n";
  my @forward_pos = map { 
    $bindings_ref->[$_]->describe_position("forward",
					   $obj_ref->[$_]
					  );
  } (0 .. $object_count - 1);
  $oddness = find_odd( @forward_pos );
  if ($oddness) {
    my $new_cat = 
      $self->derive_blemish_position( $oddness->{repeated_value} );
    return ( $new_cat );    
  }

  #print "BACKWARD\n";
  # Lets try "backward positions", now!
  my @backward_pos = map { 
    $bindings_ref->[$_]->describe_position("backward",
					   $obj_ref->[$_]
					  );
  } (0 .. $object_count - 1);
  $oddness = find_odd( @backward_pos );
  if ($oddness) {
    my $new_cat = 
      $self->derive_blemish_position( $oddness->{repeated_value} );
    return ( $new_cat );    
  }



  return ();

}

sub SBindings::describe_position{
  my ( $self, $string, $built_obj ) = @_;
  my @where = @{ $self->get_where };
  @where == 1 or confess "This half baked function should not have been called when the number of blemishes is " . scalar(@where); 
  if ($string eq "forward") {
    return SPos->new($where[0] + 1);
  } elsif ($string eq "backward") {
    my $obj_size = scalar( @{ $built_obj->items });
    return SPos->new( $where[0] - $obj_size);
  }


  croak "unknown string argument '$string' passed to describe_position\n";
}

sub oddman_categorical{
  my ( $obj_ref, $cat_ref ) = @_;
  for my $cat ( @$cat_ref ) {
    my @bindings = map { $cat->is_instance( $_ ) } @$obj_ref;
    my @definedness = map { defined($_) ? 1 : 0 } @bindings;
    my $oddness = find_odd( @definedness );
    if ( $oddness ) {
      if ( $oddness->{repeated_value} == 1) {
	# $cat is the solution we seek!
	my $pos = $oddness->{odd_position};
	print "The odd man is: ", 
	  join(", ", $obj_ref->[$pos]->flatten), "\n";
	print "Everything else is an instance of the category '",
	  $cat->get_name(), "'.\n";
	return 1;
      } else {
	my $pos = $oddness->{odd_position};
	print join(", ", $obj_ref->[$pos]->flatten), 
	  " can be construed to be an odd man: it is the only one that belongs to the category '", $cat->get_name(), "'\n";
	print "But I shall look for other solutions\n";
      }
    } else {
      # All are defined or none is!
      if (SUtil::all(@definedness)) {
	# Okay, all items are instances of this category!
	print "Everything is an instance of the category '", $cat->get_name(), "'. I'll see what I can do\n";
	my @secondary_cats = 
	  $cat->generate_secondary_cats($obj_ref, \@bindings );
	my $ret = oddman_categorical( $obj_ref, \@secondary_cats );
	return 1 if $ret;
	print "No, drew a blank there!\n\n";
      }
    }
  }
}

sub SCat::generate_secondary_cats{
  my ( $self, $obj_ref, $bindings_ref ) = @_;
  print "#" x 10, "\n";
  print "Processing for ", $self->get_name(), " further...\n";
  print "Attributes: ";
  my @att = $self->get_att()->members();
  print join(", ", @att), "\n";
  my %posn_assumption_hash;
  for my $att (@att) {
    my @this_att_values = map { $_->{$att} } @$bindings_ref;
    my $oddness = find_odd( @this_att_values );
    next unless $oddness;
    print "\t$att can be used to distinguish!\n";
    push @{ $posn_assumption_hash{ $oddness->{odd_position} } },
      $att, $oddness->{repeated_value};
  }
  if (%posn_assumption_hash) {
    return map { $self->derive_assuming( { @$_ } )  
	} values %posn_assumption_hash;
  }

  # Since we got here, attribute names cannot get the job done. Since we do not yet have adjectives, we'd have to call it quits here...

  # Unless we try blemishes! Lets...
  my @blemish_categories = 
    $self->generate_secondary_blemish_cats( $obj_ref, $bindings_ref );
  return @blemish_categories;
}

sub find_odd{
  my @input = @_;
  croak "need at least three arguments" unless @input >= 3;
  my ($odd_pos, $odd_value, $repeated_value);
  if ($input[0] eq $input[1]) {
    # odd isn't first or second!
    $repeated_value = $input[0];
    for (my $i=2; $i < @input; $i++) {
      next if $input[$i] eq $input[0];
      $odd_pos = $i;
      $odd_value = $input[$i];
      last;
    }
  } else { # first or second is odd
    if ($input[0] eq $input[2]) {
      $odd_pos = 1;
      $odd_value = $input[1];
      $repeated_value = $input[0];
    } else {
      $odd_pos = 0;
      $odd_value = $input[0];
      $repeated_value = $input[1];
    }
  }

  return unless defined $odd_pos;

  # So: a problematic position is guessed, along with value
  for (my $i=0; $i < @input; $i++) {
    if ($i == $odd_pos) {
      next if $input[$i] eq $odd_value;
      return;
    } else {
      next if $input[$i] eq $repeated_value;
      return;
    }
  }
  return { odd_position    => $odd_pos,
	   odd_value       => $odd_value,
	   repeated_value  => $repeated_value
	 };
}

