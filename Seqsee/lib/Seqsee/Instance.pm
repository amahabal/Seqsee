use MooseX::Declare;
use MooseX::AttributeHelpers;
role Seqsee::Instance {
  has cat_bindings => (
    metaclass => 'Collection::Hash',
    is        => 'ro',
    isa       => 'HashRef[SBindings]',
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

  sub add_category {
    scalar(@_) == 3 or die "Expected 3 arguments.";
    my ($self,  $cat, $binding ) = @_;
    $StrToCat{$cat} = $cat;
    $self->set_cat_bindings( $cat, $binding );
    $self->AddHistory( "Added category " . $cat->get_name );
  }


  sub remove_category {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $cat) = @_;
    if ( $self->has_cat_bindings($cat) )
    {
      $self->AddHistory( "Removed category " . $cat->get_name );
      $self->delete_cat_bindings($cat);
    }
    $StrToCat{$cat} = $cat;
  }


  sub get_categories {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    [ @StrToCat{ $self->category_keys } ]
   }

  sub get_categories_as_string {
    scalar(@_) == 1 or die "Expected 1 argument.";
    my ($self) = @_;
    $self->category_keys;
  }


  sub GetBindingForCategory {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $cat) = @_;
    $self->get_cat_bindings($cat);
  }


  sub is_of_category_p {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $cat) = @_;
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


  sub CopyCategoriesTo {
    scalar(@_) == 2 or die "Expected 2 arguments.";
    my ($self, $to) = @_;
    my $any_failure_so_far;
    for my $category ( @{ $self->get_categories() } ) {
      my $bindings;
      unless ( $bindings = $to->describe_as($category) ) {
        $any_failure_so_far++;
        next;
      }
    }
    return $any_failure_so_far ? 0 :1;
  }

  sub get_blemish_cats {
    my $self = shift;
    my %ret;
    while ( my ( $k, $binding ) = each %{ $self->cat_bindings } ) {
      if ( $S::Str2Cat{$k}->is_blemished_cat ) {
        $ret{$k} = $binding->{what};
      }
    }
    return \%ret;
  }

  sub HasNonAdHocCategory {
    my ($self) = @_;
    for ( $self->category_keys ) {
      return 1 unless $_ =~ m#Interlaced#;
    }
    return 0;
  }
};
