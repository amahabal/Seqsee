package SCat::OfObj::Assuming;
use strict;
use base qw{SCat::OfObj};
use Class::Std;
use Smart::Comments;
use Class::Multimethods;
use Memoize;
use Carp;

multimethod 'find_reln';
multimethod 'apply_reln';

my %BaseCategory_of : ATTR(:name<base_category>);
my %AssumingRef_of : ATTR(:name<assuming_ref>);
my %Encoding_of : ATTR(:name<encoding>);

{
  my %MEMO;

  sub Create {
    my ( $package, $base_category, $assuming_ref ) = @_;
    my $string = SLTM::encode( $base_category, $assuming_ref );
    return (
      $MEMO{$string} ||= $package->new(
        {
          base_category => $base_category,
          assuming_ref  => $assuming_ref,
          encoding      => $string,
        }
      )
    );
  }
}

# Create an instance of the category stored in $self.
sub build {
  my ( $self, $opts_ref ) = @_;
  my $id = ident $self;

  my $category      = $BaseCategory_of{$id};
  my %assuming_hash = %{ $AssumingRef_of{$id} };

  while ( my ( $k, $v ) = each %assuming_hash ) {
    if ( exists $opts_ref->{$k} ) {
      confess "This category needs $k=>$v, but got $k=> $opts_ref->{$k} instead"
      unless $opts_ref->{$k} eq $v;
    }
    else {
      $opts_ref->{$k} = $v;
    }
  }
  my $ret = $category->build($opts_ref);

  $ret->add_category( $self, SBindings->create( {}, $opts_ref, $ret ) );
  return $ret;
}

sub Instancer {
  my ( $self, $object ) = @_;
  my $id = ident $self;

  my $bindings = $BaseCategory_of{$id}->is_instance($object);
  return unless $bindings;

  my $bindings_ref = $bindings->get_bindings_ref;
  ## $bindings_ref
  my %assuming_hash = %{ $AssumingRef_of{$id} };
  while ( my ( $k, $v ) = each %assuming_hash ) {
    ## Keys: $k, $v
    return unless ( $bindings_ref->{$k} eq $v );
  }
  ## $bindings
  return $bindings;
}

sub get_name {
  my ($self) = @_;
  my $id = ident $self;

  return $BaseCategory_of{$id}->get_name() . ' with '
  . join( ', ', %{ $AssumingRef_of{$id} } );
}

*as_text = *get_name;

sub get_memory_dependencies {
  my ($self) = @_;
  my $id = ident $self;
  return ( $BaseCategory_of{$id},
    ( grep { ref($_) } values %{ $AssumingRef_of{$id} } ) );
}

sub serialize {
  my ($self) = @_;
  my $id = ident $self;
  return $Encoding_of{$id};
}

sub deserialize {
  my ( $package, $string )       = @_;
  my ( $cat,     $assuming_ref ) = SLTM::decode($string);
  return $package->Create( $cat, $assuming_ref );
}

memoize('get_name');
memoize('as_text');

sub get_pure {
  return $_[0];
}

sub AreAttributesSufficientToBuild {
  my ( $self, @atts ) = @_;
  return 1;
}
1;

1;
