package SCat::ad_hoc;
use Carp;
use Smart::Comments;

my %Memoize;

my $builder = sub {
    my ( $self, $args_ref ) = @_;
    my $parts_count = $args_ref->{parts_count} or confess "Need parts_count";
    return $Memoize{$parts_count} if exists $Memoize{$parts_count};

    my $name = "ad_hoc_$parts_count";
    my $instancer = sub {
        my ( $self, $object ) = @_;
        my $parts_ref = $object->get_parts_ref;
        ## $parts_ref
        ## $parts_count
        ## instancer called for: $name
        return unless scalar(@$parts_ref) == $parts_count;

        my %bdgs = ();
        for my $i ( 1 .. $parts_count) {
            $bdgs{"part_no_$i"} = $parts_ref->[$i-1];
        }
        return SBindings->create({}, \%bdgs, $object);
    };
    my $builder = sub {
        my ( $self, $args_ref ) = @_;
        my @ret_parts;
        
        for my $i (1..$parts_count) {
            push @ret_parts, $args_ref->{"part_no_$i"};
        }

        return SObject->create( @ret_parts );
    };



    my $ret_cat = SCat::OfObj->new(
        { name    => $name,
          builder => $builder,
          to_guess => [],
          att_type => {},
          empty_ok => 0,
          instancer => $instancer,
      }
            );
    return ( $Memoize{$parts_count} = $ret_cat );
};

our $AD_HOC = SCat::OfCat->new(
    {
        name => "AdHoc",
        builder => $builder,
        empty_ok => 0,
            }
);

1; 
