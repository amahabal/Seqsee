use MooseX::Declare;
class SElement {

  sub create {
    my ( $package, $mag, $pos ) = @_;
    Seqsee::Element->create( $mag, $pos );
  }
};
