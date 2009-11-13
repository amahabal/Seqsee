use MooseX::Declare;
use Seqsee::Object;
use Seqsee::Anchored;
use Seqsee::Element;

class SObject {
  sub create {
    my $package = shift;
    return Seqsee::Object->create(@_);
  }

  sub CreateObjectFromStructure {
    Seqsee::Object::CreateObjectFromStructure(@_);
  }
};
