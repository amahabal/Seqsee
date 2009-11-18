use 5.10.1;
use MooseX::Declare;
use MooseX::AttributeHelpers;

class Seqsee::Mapping {
  use Class::Multimethods;

  multimethod FindTransform => ( '*', '*', '*' ) => sub {
    *__ANON__ = "((__ANON__ FindTransform ***))";
    my ( $a, $b, $cat ) = @_;
    $cat->FindTransformForCat( $a, $b );
  };

  {
    my $numeric_FindTransorm = sub {
      *__ANON__ = "((__ANON__ FindTransform SInt/SElement SInt/SElement))";
      my ( $a, $b ) = @_;
      my @common_categories = $a->get_common_categories($b) or confess;
      if ( grep { not defined $_ } @common_categories ) {
        confess
        "undef in common_categories FindTransform SInt/SElement SInt/SElement:"
        . join( ', ', @common_categories );
      }
      my $cat = SLTM::SpikeAndChoose( 0, @common_categories ) // $S::NUMBER;
      if ( $cat->IsNumeric() ) {
        $cat->FindTransformForCat( $a->get_mag(), $b->get_mag() );
      }
      else {
        $cat->FindTransformForCat( $a, $b );
      }
    };
    multimethod FindTransform => qw{SInt SInt}         => $numeric_FindTransorm;
    multimethod FindTransform => qw{SElement SElement} => $numeric_FindTransorm;
  }

  multimethod FindTransform => qw(# #) => sub {
    *__ANON__ = "((__ANON__ FindTransform ##))";
    my ( $a, $b ) = @_;
    $S::NUMBER->FindTransformForCat( $a, $b );
  };

  multimethod FindTransform => qw(Seqsee::Anchored Seqsee::Anchored) => sub {
    *__ANON__ = "((__ANON__ FindTransform SAnchored SAnchored))";
    my ( $a, $b ) = @_;
    my @common_categories = $a->get_common_categories($b) or return;
    my $cat = SLTM::SpikeAndChoose( 10, @common_categories ) or return;
    $cat->FindTransformForCat( $a, $b );
  };

  # More FindTransform in Seqsee::Mapping::Dir

  multimethod ApplyTransform => qw(Seqsee::Mapping::Numeric #) => sub {
    *__ANON__ = "((__ANON__ ApplyTransform Seqsee::Mapping::Numeric #))";
    my ( $transform, $num ) = @_;
    $transform->get_category()->ApplyTransformForCat( $transform, $num );
  };

  multimethod ApplyTransform => qw(Seqsee::Mapping::Numeric SInt) => sub {
    *__ANON__ = "((__ANON__ ApplyTransform Seqsee::Mapping::Numeric SInt))";
    my ( $transform, $num ) = @_;
    my $new_mag =
    $transform->get_category()
    ->ApplyTransformForCat( $transform, $num->get_mag() ) // return;
    SInt->new($new_mag);
  };

  multimethod ApplyTransform => qw(Seqsee::Mapping::Numeric Seqsee::Element) => sub {
    *__ANON__ = "((__ANON__ ApplyTransform Seqsee::Mapping::Numeric SElement))";
    my ( $transform, $num ) = @_;
    my $new_mag =
    $transform->get_category()
    ->ApplyTransformForCat( $transform, $num->get_mag() ) // return;
    SElement->create( $new_mag, -1 );
  };

  multimethod ApplyTransform => qw(Seqsee::Mapping::Structural Seqsee::Object) => sub {
    my ( $transform, $object ) = @_;
    $transform->get_category()->ApplyTransformForCat( $transform, $object );
  };

  {
    my $Fail = sub {
      return;
    };
    multimethod FindTransform  => qw{SInt Seqsee::Element}                => $Fail;
    multimethod FindTransform  => qw{Seqsee::Element SInt}                => $Fail;
    multimethod FindTransform  => qw{Seqsee::Anchored SInt}               => $Fail;
    multimethod FindTransform  => qw{SInt Seqsee::Anchored}               => $Fail;
    multimethod ApplyTransform => qw{Seqsee::Mapping::Numeric Seqsee::Anchored} => $Fail;
  }

  sub CheckSanity {
    my ($self) = @_;
    return 1 unless $self->isa('Seqsee::Mapping::Structural');
    my $cat  = $self->get_category();
    my @atts = keys %{ $self->get_changed_bindings };
    unless ( $cat->AreAttributesSufficientToBuild(@atts) ) {
      my $cat_name = $cat->as_text();
      main::message("This transform is bogus! CAT=$cat_name ATTS=@atts");

      # die("This transform is bogus! CAT=$cat_name ATTS=@atts");
      return;
    }
    return 1;
  }

  1;
};

