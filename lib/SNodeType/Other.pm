package SNodeType::Other;

our @ISA = qw{SNode};

sub new{
  my $package = shift;
  my %args    = @_;
  my $self = bless { shortname => $args{shortname},
		     type      => "Other",
		   }, $package;
  $self->SUPER::init;
  $self;
}

sub find_links{
  # These are specialized nodes, and as such there are no rules about links.
}

1;
