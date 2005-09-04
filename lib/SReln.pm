package SReln;

use Smart::Comments;
use Class::Std;
my %name_of :ATTR( :get<name> :set<name> );
my %structure_of :ATTR;
my %finder_sub_of_of :ATTR;

my %default_finder_sub_of;

$default_finder_sub_of{"right BuiltObj"} =
    sub {
        my ( $reln, $obj ) = @_;
        my $id = ident $reln;
        my $structure = $structure_of{ $id};
        ### Structure: $structure
        foreach my $cat_name (keys %$structure) {
            my $cat = $SCat::Str2Cat{$cat_name};
            my $bindings = $cat->is_instance( $obj );
            ### $bindings
            next unless $bindings;
            my $new_bindings = build_right($bindings, $structure->{$cat_name});
            ### $new_bindings
        }
        return;
    };

our $r_succ = SReln->new({ 
    name => "successor",
    finder_subs => 
        {
            "right numeric" => sub 
                {
                    return $_[1] + 1;
                },
            "left numeric" => sub 
                {
                    return $_[1] - 1;
                },
        },
            
});
our $r_pred = SReln->new(
    { name => "predecessor",
      finder_subs => 
          {
              "right numeric" => sub 
                  {
                      return $_[1] - 1;
                  },
              "left numeric" => sub 
                  {
                      return $_[1] + 1;
                  },
          },
      
  });

our $r_same = SReln->new({ 
    name => "same",
    finder_subs => 
        {
            "right numeric" => sub 
                {
                    return $_[1];
                },
            "left numeric" => sub 
                {
                    return $_[1];
                },
        },
            
});

sub BUILD{
    my ( $self, $id, $opts_ref ) = @_;
    $name_of{$id} = $opts_ref->{name} || "";
    my $finder_sub_ref = $opts_ref->{finder_subs};
    if ($finder_sub_ref) {
        $finder_sub_of_of{$id} = $finder_sub_ref;
    }
    $structure_of{$id} = $opts_ref->{structure};
}

sub get_finder_sub{
    my ( $reln, $direction, $type ) = @_;
    my $sub = $finder_sub_of_of{ident $reln}{"$direction $type"};
    return $sub if $sub;
    $sub = $default_finder_sub_of{"$direction $type"};
    return $sub;
}

use Class::Multimethods;
multimethod '_find_reln';
multimethod find_reln => qw(SBuiltObj SBuiltObj) =>
    sub {
        my ( $o1, $o2 ) = @_;
        my @common_categories =
            $o1->get_common_categories($o2);
        ## common_categories: @common_categories
        my %reln_hash = ();

        foreach my $cat (@common_categories) {
            my ($bindings1, $bindings2)
                = map { $_->get_cat_bindings($cat) } ($o1, $o2);
            ### $bindings1, $bindings2
            my $this_category_relation;
            eval { $this_category_relation =
                       _find_reln($bindings1, $bindings2); };
            next if ( $EVAL_ERROR or 
                          not(defined $this_category_relation));
            $reln_hash{$cat} = $this_category_relation;
        }

        if (%reln_hash) {
            return SReln->new({ structure => { %reln_hash } });
        }

        return;
    };



NUMERIC_RELN: {
    my %diff_to_reln =
        ( 1  => $r_succ,
          0  => $r_pred,
          -1 => $r_same,
              );
    multimethod find_reln => ('#', '#') =>
        sub {
            my ($x, $y) = @_;
            my $diff = $y - $x;
            my $reln = $diff_to_reln{$diff};
            return $reln;
        };
}

multimethod build_right => ('SReln', '#') =>
    sub {
        my ($reln, $obj) = @_;
        my $right_finder = $reln->get_finder_sub("right",
                                                 "numeric");
        return $right_finder->( $reln, $obj );
    };

multimethod build_right => qw(SReln SBuiltObj) =>
    sub {
        my ($reln, $obj) = @_;
        my $right_finder = $reln->get_finder_sub("right",
                                                 "BuiltObj");
        return $right_finder->( $reln, $obj );
    };
    
multimethod build_left => ('SReln', '#') =>
    sub {
        my ( $reln, $obj ) = @_;
        my $left_finder = $reln->get_finder_sub("left", 
                                                "numeric");
        return $left_finder->( $reln, $obj );
    };

multimethod sequal_strict => ('#', '#') => 
    sub {
        return $_[0] == $_[1];
    };


1;
