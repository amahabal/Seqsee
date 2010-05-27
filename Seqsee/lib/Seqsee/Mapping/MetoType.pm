use 5.10.1;
use MooseX::Declare;
use MooseX::AttributeHelpers;
class Seqsee::Mapping::MetoType {
  use Class::Multimethods;

  has category => (
    is  => 'rw',
    isa => 'Any'
  );

  method get_category() {
    $self->category;
  }

  method set_category($new_val) {
    $self->category($new_val);
  }

  has name => (
    is  => 'rw',
    isa => 'Str'
  );

  method get_name() {
    $self->name;
  }

  method set_name($new_val) {
    $self->name($new_val);
  }

  has changes => (
    metaclass => 'Collection::Hash',
    is        => 'ro',
    isa       => 'HashRef[Any]',
    default   => sub { {} },
    provides  => {
      'get'    => 'get_change',
      'set'    => 'set_change',
      'exists' => 'has_change',
      'delete' => 'remove_change',
    }
  );

  method get_change_ref() {
    $self->changes;
  }

  method set_change_ref($new_val) {
    $self->changes($new_val);
  }

  sub create {
    my ( $package, $opts_ref ) = @_;
    my $string = join( ';',
      $opts_ref->{category}, $opts_ref->{name}, %{ $opts_ref->{changes} } );
    state %MEMO;
    return $MEMO{$string} ||= $package->new($opts_ref);
  }

  method FlippedVersion() {
    my $change_ref = $self->changes();
    my %new_change;
    while ( my ( $k, $v ) = each %$change_ref ) {
      $new_change{$k} = $v->FlippedVersion;
    }
    my $name = $self->name();
    my $new_name =
    ( $name =~ m#^flipped_# ) ? substr( $name, 8 ) :"flipped_$name";
    return Seqsee::Mapping::MetoType->create(
      {
        category => $self->category(),
        name     => $new_name,
        changes  => \%new_change
      }
    );
  }

  multimethod FindMapping => qw(SMetonymType SMetonymType) => sub {
    my ( $m1, $m2 ) = @_;
    my $cat1 = $m1->get_category;
    return unless $m2->get_category() eq $cat1;

    my $name1 = $m1->get_name;
    return unless $m2->get_name() eq $name1;

    # Now the meat: the info lost
    my $info_loss1 = $m1->get_info_loss;
    my $info_loss2 = $m2->get_info_loss;

    return unless scalar( keys %$info_loss1 ) == scalar( keys %$info_loss2 );
    my $change_ref = {};
    while ( my ( $k, $v ) = each %$info_loss1 ) {
      return unless exists $info_loss2->{$k};
      my $v2 = $info_loss2->{$k};
      my $rel = FindMapping( $v, $v2 ) or return;
      $change_ref->{$k} = $rel;
    }
    return Seqsee::Mapping::MetoType->create(
      {
        category => $cat1,
        name     => $name1,
        changes  => $change_ref,
      }
    );

  };

  multimethod ApplyMapping => qw(Seqsee::Mapping::MetoType SMetonymType) => sub {
    my ( $rel, $meto ) = @_;
    my $meto_info_loss = $meto->get_info_loss;

    my $rel_change_ref = $rel->get_change_ref;

    my $new_loss = {};
    while ( my ( $k, $v ) = each %$meto_info_loss ) {
      if ( not( exists $rel_change_ref->{$k} ) ) {
        $new_loss->{$k} = $v;
        next;
      }
      my $v2 = ApplyMapping( $rel_change_ref->{$k}, $v );
      $new_loss->{$k} = $v2;
    }
    return SMetonymType->new(
      {
        info_loss => $new_loss,
        name      => $meto->get_name,
        category  => $meto->get_category,
      }
    );

  };

  method get_memory_dependencies() {
    my $id = ident $self;
    return grep { ref($_) } ( $self->category(), values %{ $self->changes() } );
  }

  method serialize() {
    my $id = ident $self;

    return SLTM::encode( $self->category(), $self->name(), $self->changes() );
  }

  sub deserialize {
    my ( $package, $str ) = @_;
    my %opts;
    @opts{qw(category name changes)} = SLTM::decode($str);
    return $package->create( \%opts );
  }

  method as_text() {
    my $id = ident $self;

    my $change   = SUtil::StringifyForCarp( $self->changes() );
    my $category = SUtil::StringifyForCarp( $self->category() );
    return "SReln::MetoType[$id](change=>$change, category=>$category)";
  }

  sub get_pure {
    return $_[0];
  }

  method IsEffectivelyASamenessRelation() {
    while ( my ( $k, $v ) = each %{ $self->changes() } )
    {
      return unless $v->IsEffectivelyASamenessRelation;
    }
    return 1;
  };
};

1;
