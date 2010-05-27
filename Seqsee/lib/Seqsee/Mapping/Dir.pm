use 5.10.1;
use MooseX::Declare;
use MooseX::AttributeHelpers;
class Seqsee::Mapping::Dir {
  use Class::Multimethods;

  has string => (
    is  => 'rw',
    isa => 'Str',
  );

  sub create {
    my ( $package, $string ) = @_;
    state %MEMO;
    return $MEMO{$string} ||= $package->new( string => $string );
  }

  sub get_memory_dependencies {
    return;
  }

  our $Same      = Seqsee::Mapping::Dir->create('Same');
  our $Different = Seqsee::Mapping::Dir->create('Different');
  our $Unknown   = Seqsee::Mapping::Dir->create('Unknown');

  method IsEffectivelyASamenessRelation() {
    return $self eq $Same ? 1 :0;
  }

  multimethod FindMapping => qw(DIR DIR) => sub {
    my ( $da, $db ) = @_;
    if ( $da eq DIR::RIGHT() ) {
      return
       ( $db eq DIR::RIGHT() ) ? $Same
      :( $db eq DIR::LEFT() )  ? $Different
      :                          $Unknown;
    }
    elsif ( $da eq DIR::LEFT() ) {
      return
       ( $db eq DIR::RIGHT() ) ? $Different
      :( $db eq DIR::LEFT() )  ? $Same
      :                          $Unknown;
    }
    else {
      return $Unknown;
    }
  };

  multimethod ApplyMapping => qw{Seqsee::Mapping::Dir DIR} => sub {
    my ( $transform, $dir ) = @_;
    if ( $transform eq $Same ) {
      return $dir;
    }
    elsif ( $transform eq $Different ) {
      return $dir->Flip();
    }
    return $DIR::UNKNOWN;
  };

  sub FlippedVersion {
    return $_[0];
  }

  sub get_pure {
    return $_[0];
  }

  method serialize() {
    return $self->string;
  }

  sub deserialize {
    my ( $package, $str ) = @_;
    $package->create($str);
  }
};

1;
