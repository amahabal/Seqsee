package SBuiltObj;
use strict;
use Carp;
use Class::Std;

use base qw{SInstance};

my %items : ATTR;

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    $self->set_items( $opts_ref->{items} );
}

=pod

new_deep does a bunch of things...

=cut

sub new_deep {
    my $package = shift;
    my @items = map {
        if ( ref $_ )
        {
            if ( ref($_) eq 'ARRAY' ) {
                $package->new_deep(@$_);
            }
            else {
                $_->clone;
            }
        }
        else {
            SInt->new( { mag => $_ } );
        }
    } @_;
    my $self = $package->new( { items => [@items] } );
    $self;
}

sub new_from_string {
    my ( $package, $string ) = @_;

    #print "String is: '$string'\n";
    chomp $string;
    confess
        "strings may only use digits and (), not anything else. I got the string '$string'"
        if $string =~ m/[^\s\d,\(\)]/;
    $string = " $string ";
    for ($string) {

        #print "String is: '$_'\n";
        s#[^\s\d\(\)]# #g;
        s#(\d)(\D)#$1, $2#g;

        #print "String is: '$_'\n";
        s#\)#), #g;
        $_ = "( $_ )";
        s#,\s*\)#)#g;
        s#\(#[#g;
        s#\)#]#g;

        #print "String is: '$_'\n";
    }

    #print "String is: '$string'\n";
    my $arr_ref = eval $string;
    return $package->new_deep(@$arr_ref);
}

sub set_items {
    my ( $self, $items_ref ) = @_;
    $items{ ident $self }
        = [ map { ( ref $_ ) ? $_->clone : SInt->new( { mag => $_ } ) }
            @$items_ref ];
    $self;
}

sub items {
    $items{ ident shift };
}

sub flatten {
    my $self = shift;
    return map { $_->flatten() } @{ $items{ ident $self} };
}

sub find_at_position {
    my ( $self, $position ) = @_;
    UNIVERSAL::isa( $position, "SPos" ) or croak "Need SPos";
    my $range = $position->find_range($self);
    return $self->subobj_given_range($range);
}

sub subobj_given_range {
    my ( $self, $range ) = @_;
    my $items_ref = $items{ ident $self };
    my @ret;
    for (@$range) {
        my $what = $items_ref->[$_];
        defined $what or croak "out of range";
        push @ret, $what;
    }
    return @ret;
}

sub get_position_finder {
    my ( $self, $str ) = @_;
    my @cats               = $self->get_cats();
    my @cats_with_position =
        grep { $_->has_named_position($str) } @cats;
    ( @cats_with_position == 1 )
        or croak
        "Could not find any way for finding the position '$str' for $self"
        . " Or maybe found too many ways";

    # XXX what if multiple categories have a position of this name??
    return $cats_with_position[0]->{position_finder}{$str};
}

sub splice {
    ( @_ == 4 ) or croak "syntax of splice has changed";
    my ( $self, $from, $len, $rest_ref ) = @_;
    my $items_ref = $items{ ident $self};
    splice( @$items_ref, $from, $len, @$rest_ref );
    return $self;
}

sub apply_blemish_at {
    my ( $self, $blemish, $position ) = @_;
    UNIVERSAL::isa( $blemish,  "SBlemishType" ) or croak "need SBlemish";
    UNIVERSAL::isa( $position, "SPos" )     or croak "need SPos";
    $self = $self->clone;
    my $range = $position->find_range($self);
    croak "position $position undefined for $self" unless $range;
    my @subobjs = $self->subobj_given_range($range);
    if ( @subobjs >= 2 ) {
        croak
            "applying blemished over a range longer than 1 not yet implemented";
    }
    my $blemished = $blemish->blemish( $subobjs[0] );

    #$blemished->show();
    my $range_start  = $range->[0];
    my $range_length = scalar(@$range);
    $self->splice( $range_start, $range_length, [$blemished] );

    #$self->show;
    $self;
}

sub clone {
    my $self = shift;
    my @items = map { ref($_) ? $_->clone() : $_ } @{ $items{ ident $self} };
    my $new_obj = new SBuiltObj( { items => \@items } );
    $new_obj->set_cats_hash( $self->get_cats_hash() );
    $new_obj;
}

sub show {
    my $self = shift;
    print "Showing the structure of $self:\n";
    print "\nItems:\n";
    foreach ( @{ $items{ ident $self} } ) {
        print "\t$_\n";
        if ( ref $_ ) {
            $_->show_shallow(2);
        }
    }
}

sub show_shallow {
    my ( $self, $depth ) = @_;
    foreach ( @{ $self->items } ) {
        print "\t" x $depth;
        print "$_\n";
        if ( ref $_ ) {
            $_->show_shallow( $depth + 1 );
        }
    }
}

sub structure_is {    # To be called by structure_ok
    my ( $self, $potential_struct ) = @_;
    my $self_struct = $self->get_structure();
    $potential_struct = $potential_struct->get_structure()
        unless ( !ref($potential_struct)
        or ref($potential_struct) eq "ARRAY" );
    return SUtil::compare_deep( $self_struct, $potential_struct );
}

sub has_structure_one_of {
    my $self = shift;
    for (@_) {
        my $struct = ( UNIVERSAL::isa( $_, "SBuiltObj" ) )
            ? $_->get_structure()
            : $_;
        return 1 if $self->structure_is($struct);
    }
    return 0;
}

sub get_structure {
    my $self = shift;
    [ map { $_->get_structure } @{ $items{ ident $self} } ];
}

sub semiflattens_ok {
    my ( $self, @objects ) = @_;

    # XXX clearly incomplete. Stopgap
    # should flatten only part way
    my @self_flatten = $self->flatten;
    my @other_flatten = map { $_->flatten } @objects;
    return 0 unless @self_flatten == @other_flatten;
    for ( my $i = 0; $i < @self_flatten; $i++ ) {
        return 0 unless $self_flatten[$i] == $other_flatten[$i];
    }
    return 1;
}

sub as_int {
    my $self = shift;
    return $items{ ident $self}[0]->as_int()
        if scalar( @{ $items{ ident $self} } ) == 1;

    my $bl_cats = $self->get_blemish_cats;
    my %ret;
    while ( my ( $blemish, $what ) = each %$bl_cats ) {
        my @what_as_int = $what->as_int;
        foreach (@what_as_int) { $ret{$_}++ }
    }
    return sort { $ret{$b} <=> $ret{$a} } keys %ret;
}

sub can_be_as_int {
    my ( $self, $int ) = @_;
    my @int_vals = $self->as_int();
    for (@int_vals) { return 1 if $_ == $int }
    return undef;
}

sub can_be_seen_as_int {
    my ( $self, $int ) = @_;

    # use Smart::Comments;
    ### can_be_seen_as_int: $self, $int
    if ( scalar( @{ $items{ ident $self} } ) == 1
        and my $bindings = $items{ ident $self}[0]->can_be_seen_as_int($int) )
    {
        ### Single item: $bindings
        return $bindings;
    }
    my $bl_cats = $self->get_blemish_cats;
    while ( my ( $blemish, $what ) = each %$bl_cats ) {
        my $bindings = $what->can_be_seen_as_int($int);
        ### bindings for $bl_cats: $bindings
        next unless $bindings;
        unless ( ref $bindings ) {
            $bindings = new SBindings::Blemish;
        }
        $bindings->set_real($what);
        $bindings->set_starred($int);
        return $bindings;
    }
    return;
}

sub structure_blearily_ok {

    # XXX THIS FUNCTION IS REDICULOUSLY KLUDGY!!
    my ( $self, $template ) = @_;

    # use Smart::Comments;
    ### $self, $template
    my @my_items = @{ $items{ ident $self} };
    my @template_items;
    if ( ref($template) eq "ARRAY" ) {
        @template_items = map { SInt->new( { mag => $_ } ) } @$template;
    }
    elsif ( ref($template) eq "SBuiltObj" ) {
        @template_items = @{ $template->items };
    }
    elsif ( ref($template) eq "SInt" ) {

        #return unless @my_items == 1;
        #return $my_items[0]->structure_blearily_ok( $template->get_mag );
        return unless $self->can_be_seen_as_int( $template->get_mag );
        return SBindings->new();
    }
    else {
        return unless @my_items == 1;
        return $my_items[0]->structure_blearily_ok($template);
    }
    return undef unless scalar(@my_items) == scalar(@template_items);
    ### Item count identical:
    my @blemishes;
    for ( my $i = 0; $i < scalar(@my_items); $i++ ) {
        my $my_item = $my_items[$i];
        my $t_item  = $template_items[$i];
        ### i,my_items, t_item: $i, $my_item, $t_item
        if ( UNIVERSAL::isa( $t_item, "SInt" ) ) {
            my $bindings = $my_item->can_be_seen_as_int( $t_item->get_mag() );
            ### bindings: $bindings
            if ( ref $bindings ) {
                $bindings->set_where($i);
                $bindings->set_real($my_item);
                push @blemishes, $bindings;
            }
            next if $bindings;
        }
        else {

      # XXX THIS WILL NOT RETURN BINDINGS CORRECTLY IF TEMPLATE IS NOT SHALLOW
      # print "TEMPLATE ITEM NOT AN SINT!!\n";
            next if $my_item->structure_blearily_ok($t_item);
        }
        return undef;
    }
    my $return = new SBindings;
    for (@blemishes) {
        $return->add_blemish($_);
    }
    return $return;
}

sub is_empty {
    my $self = shift;
    return 1 unless @{ $items{ ident $self} };
    return 0;
}

sub describe_as {
    ( @_ == 2 ) or croak "need two arguments";
    my ( $self, $cat ) = @_;

    # XXX Next line hardcoded... shouldn't be
    $self->seek_blemishes( [$S::double] );
    return $cat->is_instance($self);
}

sub seek_blemishes {
    my ( $self, $blemish_list ) = @_;
    my $items_ref = ( $items{ ident $self} ||= [] );
    foreach my $item (@$items_ref) {
        next if UNIVERSAL::isa( $item, "SInt" );
        foreach my $bl (@$blemish_list) {
            if ( my $bindings = $bl->is_instance($item) ) {
                $item->add_cat( $bl, $bindings );
            }
        }
    }
}

sub seek_categories {
    my $self    = shift;
    my $cat_ref = shift;
    for ( @{ $self->items } ) {
        if ( $_->isa("SBuiltObj") ) {
            $_->seek_categories($cat_ref);
        }
    }
    for (@$cat_ref) {
        if ( my $bindings = $_->is_instance($self) ) {
            $self->add_cat( $_, $bindings );
        }
    }
}

sub blemish_positions_may_be {
    my ( $self, $bindings, $pos_ref ) = @_;

    # use Smart::Comments;
    ### blemish_positions_may_be: $self, $bindings, $pos_ref
    my $where_ref = $bindings->get_where();
    return unless ( @$where_ref == @$pos_ref );
    ### Same size:
    ### where: $where_ref
    for ( my $i = 0; $i < @$pos_ref; $i++ ) {

        # XXX: what if the damned thing returns a large range?
        my $range = $pos_ref->[$i]->find_range($self);
        ### range: $range
        return unless $range;
        croak "No clue what to do if range is large!"
            if ( @$range > 1 );
        next if $range->[0] == $where_ref->[$i];
        return;
    }
    return 1;
}

sub blemish_type_may_be {
    my ( $self, $bindings, $type_ref ) = @_;

    #use Smart::Comments;
    ### blemish_type_may_be: $self, $bindings, $type_ref
    my $real_ref    = $bindings->get_real;
    my $starred_ref = $bindings->get_starred;
    return unless ( @$real_ref == @$type_ref );
    for ( my $i = 0; $i < @$type_ref; $i++ ) {
        my $bindings_inner = $type_ref->[$i]->is_instance( $real_ref->[$i] );
        ### In Loop: $i, $bindings_inner, $starred_ref
        return unless $bindings_inner;
        return
            unless $bindings_inner->{what}
            ->structure_is( $starred_ref->[$i] );
    }
    return 1;
}

1;
