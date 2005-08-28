use strict;
use Test::More;
use Test::Exception;
use Test::Deep;
use English;

use S;

sub undef_ok {
    my ( $what, $msg ) = @_;
    if ( not( defined $what ) ) {
        $msg ||= "is undefined";
        ok( 1, $msg );
    }
    else {
        $msg ||= "expected undef, got $what";
        ok( 0, $msg );
    }
}

sub instance_of_cat_ok {
    my ( $what, $cat, $msg ) = @_;
    no warnings;
    $msg ||= "$what is an instance of $cat";
    ok( $what->instance_of_cat($cat), $msg );
}

sub SInt::structure_ok {
    my ( $self, $potential_struct, $msg ) = @_;
    $msg ||= "structure of $self";
    Test::More::ok( $self->structure_is($potential_struct), $msg );
}

sub SInt::structure_nok {    # ONLY TO BE USED FROM TEST SCRIPTS
    my ( $self, $potential_struct, $msg ) = @_;
    $msg ||= "structure of $self isn't";
    Test::More::ok( !$self->structure_is($potential_struct), $msg );
}

sub SBuiltObj::structure_ok {    # ONLY TO BE USED FROM TEST SCRIPTS
    my ( $self, $potential_struct, $msg ) = @_;
    $msg ||= "structure of $self";
    Test::More::ok( $self->structure_is($potential_struct), $msg );
}

sub SBuiltObj::structure_nok {    # ONLY TO BE USED FROM TEST SCRIPTS
    my ( $self, $potential_struct, $msg ) = @_;
    $msg ||= "structure of $self isn't";
    Test::More::ok( !$self->structure_is($potential_struct), $msg );
}

sub SBindings::Blemish::where_ok {
    my ( $self, $what ) = @_;
    is $self->get_where(), $what, "$self where okay";
}

sub SBindings::Blemish::starred_ok {
    my ( $self, $what ) = @_;
    is $self->get_starred(), $what, "$self starred okay";
}

sub SBindings::Blemish::real_ok {
    my ( $self, $what ) = @_;
    ok $self->get_real()->structure_is($what), "$self real okay";
}

sub SBindings::where_ok {
    my ( $self, $what_ref ) = @_;
    my @blemishes = @{ $self->get_blemishes() };
    my $msg       = "$self where okay";
    unless ( @blemishes == @$what_ref ) {
        ok 0, $msg;
        return;
    }
    for ( my $i = 0; $i < @blemishes; $i++ ) {
        next if $blemishes[$i]->get_where() == $what_ref->[$i];
        ok 0, $msg;
    }
    ok 1, $msg;
}

sub SBindings::starred_ok {
    my ( $self, $what_ref ) = @_;
    my @blemishes = @{ $self->get_blemishes() };
    my $msg       = "$self starred okay";
    unless ( @blemishes == @$what_ref ) {
        ok 0, $msg;
        return;
    }
    for ( my $i = 0; $i < @blemishes; $i++ ) {
        next if $blemishes[$i]->get_starred() eq $what_ref->[$i];
        ok 0, $msg;
    }
    ok 1, $msg;
}

sub SBindings::real_ok {
    my ( $self, $what_ref ) = @_;
    my @blemishes = @{ $self->get_blemishes() };
    my $msg       = "$self real okay";
    unless ( @blemishes == @$what_ref ) {
        ok 0, $msg;
        return;
    }
    for ( my $i = 0; $i < @blemishes; $i++ ) {
        next if $blemishes[$i]->get_real()->structure_is( $what_ref->[$i] );
        ok 0, $msg;
    }
    ok 1, $msg;
}

sub SBindings::value_ok {
    my ( $self, $name, $val ) = @_;
    my $got_val = $self->get_values_of()->{$name};
    if ( ref $got_val ) {
        ok $got_val->structure_is($val);
    }
    else {
        ok( $got_val eq $val );
    }
}

sub SBindings::blemished_ok {
    my ($self) = shift;
    my $msg = "$self is blemished";
    ok scalar( @{ $self->get_blemishes() } ), $msg;
}

sub SBindings::non_blemished_ok {
    my ($self) = shift;
    my $msg = "$self is blemished";
    ok !scalar( @{ $self->get_blemishes() } ), $msg;
}

sub blemished_where_ok {
    my ( $bindings, $where_ref ) = @_;
    my @where = map { $_->get_where() } @{ $bindings->get_blemishes };
    cmp_deeply \@where, $where_ref, "Location of Blemished";
}

sub blemished_starred_okay {
    my ( $bindings, $star_ref ) = @_;
    my @starred = map { $_->get_starred } @{ $bindings->get_blemishes };
    cmp_deeply \@starred, $star_ref, "Starred versions of Blemished";
}

sub blemished_real_okay {
    use Smart::Comments;
    my ( $bindings, $real_ref ) = @_;
    my @real = map { $_->get_real } @{ $bindings->get_blemishes };
    my $msg = "Original (unstarred) versions of Blemished";
    if ( @real == @$real_ref ) {
        for ( my $i = 0; $i < @real; $i++ ) {
            next if $real[$i]->structure_is( $real_ref->[$i] );
            ok 0, $msg;
        }
        ok 1, $msg;
    }
    else {
        ok 0, $msg;
    }
}

1;
