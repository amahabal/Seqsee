package Test::Seqsee::filters;

use Exporter;
use Carp;

our @ISA = qw{Exporter};
our @EXPORT = qw{run_commands
		 construct_and_commands
	       };

use Test::Base;
use Test::Base::Filter -base;
use S;

sub Test::Base::Filter::Sconstruct{
  my ( $self, @data ) = @_;
  my $dataline = shift( @data );
  my $Object;
  if ($dataline =~ /^\s*(\d+)\s*$/) {
    $Object =  SInt->new( { mag => $1 });
  } else {
    $Object = SBuiltObj->new_deep( @{ eval "($dataline)" } );
  }
  if (@data) {
    # More work to do!
    for my $dataline (@data) {
      # print "Will process: '$dataline'\n";
      my ( $first_part, $rest ) = split(/\s+/, $dataline, 2);
      no strict 'refs';
      if ($first_part eq "blemish") {
	my $blemish = ${"S::$rest"};
	UNIVERSAL::isa($blemish, "SBlemish") 
	    or confess "'$rest' is not a blemish I know! ($blemish)";
	$Object = $blemish->blemish( $Object );
      } elsif ($first_part eq "blemish_at") {
	my ( $name, $pos ) = eval $rest;
	# print "name = $name, pos = $pos\n"; 
	my $blemish = ${"S::$name"};
	UNIVERSAL::isa($blemish, "SBlemish") 
	    or confess "'$rest' is not a blemish I know! ($blemish)";
	$pos = SPos->new($pos) unless UNIVERSAL::isa($pos, "SPos");
	$Object = $Object->apply_blemish_at( $blemish, $pos );
      } else {
	confess "Don't know how to '$dataline'\n";
      }
    }
  }
  return $Object;
}

sub Test::Base::Filter::oddman{
  my ( $self, @data ) = @_;
  my @built_objects = 
    map { 
      my @parts = split /\s+/, $_;
      my @chunked = SUtil::naive_brittle_chunking([@parts]);
      SBuiltObj->new_deep( @chunked ) 
    } @data;
  # print "Oddman filter: data = '", join("'\n---\n'", @built_objects), "'\n";
  return scalar( SUtil::oddman(@built_objects) );
}


sub run_commands{
  my ( $object, $command_list ) = @_;
  my $ok_so_far = 1;
  for (@$command_list) {
    $_ =~ s/^\s*//;
    $_ =~ s/\s*$//;
    my $ok = run_command( $object, $_ );
    next if ($ok);
    $ok_so_far = 0;
    print STDERR "Failed '$_'\n";
  }
  return $ok_so_far;
}

sub run_command{
  my ( $object, $command ) = @_;
  my ( $first_part, $rest ) = split(/\s+/, $command, 2);
  if ($first_part eq "isa" ) {
    return UNIVERSAL::isa( $object, $rest );
  }
  if ($first_part =~ /^\.(.*)/) {
    # method call!
    my $method = $1;
    my $value = $object->$method();
    my $rest  = eval $rest;
    # print "Got value = '$value', rest = '$rest'\n";
    return my_comapre_deep($value, $rest);
  }
  confess "Unknown MTL command '$command'";
}

sub my_comapre_deep{
  my ( $a, $b ) = @_;
  if (ref($a) =~ /ARRAY/ and ref($b) =~ /ARRAY/) {
    # print "Comparing @$a and @$b\n";
    return unless @$a == @$b;
    for (my $i = 0; $i < @$a; $i++) {
      return unless my_comapre_deep( $a->[$i], $b->[$i] );
    }
    return 1;
  } elsif (ref($a) =~ /HASH/ and ref($b) =~ /HASH/) {
    return unless (keys %$a) == keys (%$b);
    foreach my $key (keys %$a) {
      return unless my_comapre_deep( $a->{$key}, $b->{$key} );
    }
    return 1;
  } elsif (!ref($a) and !ref($b)) {
    return $a eq $b;
  } else {
    return;
  }
}

sub construct_and_commands{
  for my $block (blocks()) {
    my $constructed = $block->{construct}[0];
    # print $constructed, "\n";
    my $commands = $block->{mtl};
    ok ( run_commands( $constructed, $commands ) );
  }
}

1;
