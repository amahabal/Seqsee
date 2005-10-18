package STest::SBindings;
use base qw{Test::Class};
use Test::More;
use Test::Deep;

use S;

sub ascending1 :Test(6){
    my $cat = $S::ASCENDING;
    my ($object, $bindings);

    $object = SObject->quik_create([1, 2, 3]);
    $bindings = $cat->is_instance($object);

    ok($bindings);
    isa_ok( $bindings, "SBindings" );
    
    # Checking that things are set okay
    my $bindings_ref = $bindings->get_bindings_ref();
    cmp_ok( $bindings_ref->{start}, 'eq', 1);
    cmp_ok( $bindings_ref->{end},   'eq', 3);

    my $squinting_ref = $bindings->get_squinting_raw();
    ok( scalar(keys %$squinting_ref) == 0);

    ok($bindings->get_metonymy_mode() eq 0);

}

sub ascending2 :Test(9){
    my $cat = $S::ASCENDING;
    my ($object, $bindings);

    $object = SObject->quik_create([1, [2,2], 3]);
    $bindings = $cat->is_instance($object);

    ok($bindings);
    isa_ok( $bindings, "SBindings" );
    
    # Checking that things are set okay
    my $bindings_ref = $bindings->get_bindings_ref();
    cmp_ok( $bindings_ref->{start}, 'eq', 1);
    cmp_ok( $bindings_ref->{end},   'eq', 3);

    my $squinting_ref = $bindings->get_squinting_raw();
    ok( exists $squinting_ref->{1});
    isa_ok( $squinting_ref->{1}, "SMetonym" );

    ok($bindings->get_metonymy_mode() eq 1);
    cmp_ok($bindings->get_metonymy_cat(),  'eq', $S::SAMENESS);
    cmp_ok($bindings->get_metonymy_name(), 'eq', "each");

}

sub ascending3 :Test(9){
    my $cat = $S::ASCENDING;
    my ($object, $bindings);

    $object = SObject->quik_create([[1,1], [2,2], [3,3]]);
    $bindings = $cat->is_instance($object);

    ok($bindings);
    isa_ok( $bindings, "SBindings" );
    
    # Checking that things are set okay
    my $bindings_ref = $bindings->get_bindings_ref();
    cmp_ok( $bindings_ref->{start}, 'eq', 1);
    cmp_ok( $bindings_ref->{end},   'eq', 3);

    my $squinting_ref = $bindings->get_squinting_raw();
    ok( exists $squinting_ref->{0});
    isa_ok( $squinting_ref->{0}, "SMetonym" );

    ok($bindings->get_metonymy_mode() eq 3);
    cmp_ok($bindings->get_metonymy_cat(),  'eq', $S::SAMENESS);
    cmp_ok($bindings->get_metonymy_name(), 'eq', "each");

}


1;
