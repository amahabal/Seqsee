package SNodeType::Number;

our @ISA = qw{SNode};


sub new{
  my $package = shift;
  my %args    = @_;
  my $mag     = $args{magnitude} || die "SNodeType::Number needs 'magnitude'";
  my $self    = bless { magnitude => $mag }, $package;
  $self->{shortname} = $mag;
  $self->{type} = "Number"; #Every SNodeType::* must set this!
  $self->SUPER::init;
  $self;
}

sub find_links{
  my $self = shift;
  my @links;
  my $mag  = $self->{magnitude};
  push(@links, SDesc->new( "Number::" . ($mag + 1),
			   $Dflag::has,
			   $SNet::node_successor,
			 )
      );
  push(@links, SDesc->new( "Number::" . ($mag - 1),
			   $Dflag::has,
			   $SNet::node_predecessor,
			 )
      );
  @links;
}

1;
