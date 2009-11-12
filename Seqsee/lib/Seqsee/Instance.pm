use MooseX::Declare;

role Seqsee::Instance {
  has cat_bindings => (
    metaclass => 'Collection::Hash',
    is        => 'ro',
    isa       => 'HashRef[SBinding]',
    default   => sub { {} },
    provides  => {
      'get'    => 'get_cat_bindings',
      'set'    => 'set_cat_bindings',
      'exists' => 'has_cat_bindings',
      'delete' => 'delete_cat_bindings',
      'keys'   => 'category_keys',
    }
  );

  our %StrToCat;
  method add_category( $cat, $binding ) {
    $StrToCat{$cat} = $cat;
    $self->set_cat_bindings( $cat, $binding );
    $self->AddHistory( "Added category " . $cat->get_name );
  }

  method remove_category($cat) {
    if ( $self->has_cat_bindings($cat) )
    {
      $self->AddHistory( "Removed category " . $cat->get_name );
      $self->delete_cat_bindings($cat);
    }
    $StrToCat{$cat} = $cat;
  }

  method get_categories() { [ @StrToCat{ $self->category_keys } ] }

  method get_categories_as_string() {
    $self->category_keys;
  }

  method GetBindingsForCategory($cat) {
    $self->get_cat_bindings($cat);
  }

  method is_of_category_p($cat) {
    $self->get_cat_bindings($cat);
  }

  sub get_common_categories {
    my @objects = @_;
    my $count   = scalar(@objects);

    my %key_count;
    for my $object (@objects) {
      confess "Funny arg $object" unless ref($object);
      $key_count{$_}++ for $object->category_keys;
    }

    my @common_strings = grep { $key_count{$_} == $count } keys %key_count;
    return @StrToCat{@common_strings};
  }

  # Did not yet copy, may not be needed:
  # get_blemish_cats
  # HasNonAdHocCategory
  # CopyCategoriesTo
};
