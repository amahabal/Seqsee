package SBlemish;
use SCat;
use MyFilter;
use Perl6::Subs;
use Set::Scalar;
our @ISA = qw{SCat};

method new($package: 
	   +$blemisher of Code,
	   +$empty_ok,
	   +$empty_what,
	   +$att of Set::Scalar,
	   +$guesser,
	   +$guesser_flat
	  ){
  my $self = new SCat;
  $.att    = $att;
  $.att->insert("what");

  $blemisher or die "The blemisher must be provided!";

  $.blemisher = 
    sub($self, $what, *%options) { 
      &.builder($self, %options, what => $what); 
    };
  $.builder       = $blemisher;
  $.empty_ok      = $empty_ok;
  $.empty_what    = $empty_what;
  $.guesser       = $guesser;
  $.guesser_flat  = $guesser_flat;

  $self->compose;
  bless $self, $package;
  $._blemished = 1;
  # Now we'll do something evil
  $.instancer_flat = $self->generate_instancer_flat($guesser_flat);
  $.instancer_deep = $.instancer;
  $.instancer = 
     sub {
      my $self = shift;
      #print "In instancer\n";
      if (not(@_) or (@_ == 1 and $_[0]->is_empty)) {
	return $.empty_what if $.empty_ok;
	return undef;
      }
      my $bindings;
      if (@_ == 1) {
	#print "\tSingle object, only a deep check($_[0])\n";
	$bindings = $.instancer_deep->($self, $_[0]);
	return $bindings if $bindings;
      } else {
	#print "\tSeveral objects, only a shallow check\n";
	$bindings = $.instancer_flat->($self, @_);
	return $bindings;
      }
    };

  $self;
}


method blemish($object){
  my $ret = &.builder($self, what => $object) or return undef;
  $ret->add_cat($self, { what => $object });
  $ret;
}

method generate_instancer_flat($guesser_hash){
  my @atts = $.att->members;
  foreach (@atts) {
    $guesser_hash->{$_} or die "cannot generate flat instancer; do not know how to guess $_";
  }
  return sub {
    my ($me, @objects) = @_;
    #print "#\tIn flat instancer...args: @objects\n";
    my %guess;
    for (@atts) {
      #print "#\t\tguessing '$_'\n";
      my $guess = $guesser_hash->{$_}->($me, @objects);
      #print "#\t\t    guessed $guess\n";
      return undef unless defined $guess;
      $guess{$_} = $guess;
      #$guess->show;
    }
    my $guess_built = $me->build(%guess);
    #$guess_built->show;
    #print "\t\t guess built: $guess_built. Flattens to: ", $guess_built->flatten(), "\n";
    #print "\t\tOriginal objects flatten to: ", map { $_->flatten } @objects;
    #print "\n";
    if ( $guess_built->semiflattens_ok(@objects) ) {
      return \%guess;
    } else {
      return undef;
    }
  };
}

method unblemish($object){
  my $bindings = $self->is_instance($object) or return undef;
  $bindings->{what};
}

sub is_blemished{
  my $self = shift;
  my $obj  = shift;
  $.instancer->($self, $obj);
}

sub get_blemish_category{
  my $self = shift;
  $self->{blemish_cat} ||= $self->make_blemish_category;
}

sub make_blemish_category{
  my $self;
  my $ret = new SCat;
  $ret->{builder} = $.blemisher;
  $ret->{instancer} = $.instancer;
  $ret->{_blemished} = $self;
  $self->{blemish_cat} = $ret;
  $ret;
}

1;
