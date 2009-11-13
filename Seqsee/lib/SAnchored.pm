use MooseX::Declare;
class SAnchored {

  sub create {
    my ( $package, @items ) = @_;
    return Seqsee::Anchored->create(@items);
  }
}

