package SCategory;
use Moose::Role;
with 'LTMStorable';

requires 'Instancer';
requires 'build';
requires 'get_name';
requires 'as_text';
requires 'AreAttributesSufficientToBuild';

sub is_instance {
  my ( $cat, $object ) = @_;
  my $bindings = $cat->Instancer($object) or return;
  $object->add_category( $cat, $bindings );

  return $bindings;
}

1;
