package STest::SReln;
use base qw{Test::Class};
use Test::More;
use Test::Deep;

use S;
use Class::Multimethods;
use Smart::Comments;

multimethod find_reln;

my $o123  = SObject->quik_create([1,2,3], $S::ASCENDING);
my $o123b = SObject->quik_create([1,2,3], $S::ASCENDING);
my $o1234  = SObject->quik_create([1,2,3,4], $S::ASCENDING);
my $o23  = SObject->quik_create([2,3], $S::ASCENDING);
my $o234  = SObject->quik_create([2,3,4], $S::ASCENDING);

my $o1123f  = SObject->quik_create([[1,1], 2,3], $S::ASCENDING);
$o1123f->tell_forward_story($S::ASCENDING);
my $o1223f  = SObject->quik_create([1,[2,2],3], $S::ASCENDING);
$o1223f->tell_forward_story($S::ASCENDING);
my $o12223f  = SObject->quik_create([1,[2,2,2],3], $S::ASCENDING);
$o12223f->tell_forward_story($S::ASCENDING);

my $o1123b  = SObject->quik_create([[1,1], 2,3], $S::ASCENDING);
$o1123b->tell_backward_story($S::ASCENDING);
my $o1223b  = SObject->quik_create([1,[2,2],3], $S::ASCENDING);
$o1223b->tell_backward_story($S::ASCENDING);
my $o12223b  = SObject->quik_create([1,[2,2,2],3], $S::ASCENDING);
$o12223b->tell_backward_story($S::ASCENDING);



sub simple :Test(8){
    my $reln;

    $reln = find_reln(1,1);
    ok( $reln->get_text() eq "same" );
    isa_ok( $reln, "SReln::Simple");

    $reln = find_reln(0,0);
    ok( $reln->get_text() eq "same" );
    isa_ok( $reln, "SReln::Simple");

    $reln = find_reln(1,2);
    ok( $reln->get_text() eq "succ" );
    isa_ok( $reln, "SReln::Simple");

    $reln = find_reln(2,1);
    ok( $reln->get_text() eq "pred" );
    isa_ok( $reln, "SReln::Simple");
}

sub reln_123_123b :Test(8){
    my $reln = find_reln($o123, $o123b);
    isa_ok($reln, "SReln::Compound");
    cmp_ok($reln->get_base_category(), 'eq', $S::ASCENDING);
    cmp_ok($reln->get_base_meto_mode(), 'eq', 0);
    cmp_ok( scalar( keys %{$reln->get_unchanged_bindings_ref()}), '==', 2);
    cmp_ok( scalar( keys %{$reln->get_changed_bindings_ref()}),   '==', 0);
    
    cmp_ok( $reln->get_first(), 'eq', $o123);
    cmp_ok( $reln->get_second(), 'eq', $o123b);

    return; # skip
    my $new_object = apply_reln( $reln, $o123b);
    $new_object->structure_ok([1,2,3]);

}

sub reln_123_1234 :Test(7){
    my $reln = find_reln($o123, $o1234);
    isa_ok($reln, "SReln::Compound");
    cmp_ok($reln->get_base_category(), 'eq', $S::ASCENDING);
    cmp_ok($reln->get_base_meto_mode(), 'eq', 0);
    cmp_ok( scalar( keys %{$reln->get_unchanged_bindings_ref()}), '==', 1);
    cmp_ok( scalar( keys %{$reln->get_changed_bindings_ref()}),   '==', 1);
    cmp_ok( $reln->get_changed_bindings_ref()->{end}->get_text(), 'eq',"succ");

    return; # skip
    my $new_object = apply_reln( $reln, $o123b);
    $new_object->structure_ok([1,2,3]);

}

sub reln_1123f_1223f :Test(11){
    ## $o1123f->get_structure, $o1223f->get_structure
    my $reln = find_reln($o1123f, $o1223f);
    isa_ok($reln, "SReln::Compound");
    cmp_ok($reln->get_base_category(), 'eq', $S::ASCENDING);
    cmp_ok($reln->get_base_meto_mode(), 'eq', 1);
    cmp_ok( scalar( keys %{$reln->get_unchanged_bindings_ref()}), '==', 2);
    cmp_ok( scalar( keys %{$reln->get_changed_bindings_ref()}),   '==', 0);
    
    cmp_ok($reln->get_base_pos_mode(), 'eq', 1); # 1 is FWD
    cmp_ok($reln->get_position_reln()->get_text(), 'eq', "succ");

    my $meto_reln = $reln->get_metonymy_reln;
    cmp_ok($meto_reln->get_change_ref()->{length}->get_text(), 'eq', 'same');

    return; # skip
    my $new_object = apply_reln( $reln, $o1223b);
    $new_object->structure_ok([1,2,3]);

}

sub reln_1223f_12223f :Test(11){
    ## $o1123f->get_structure, $o1223f->get_structure
    my $reln = find_reln($o1223f, $o12223f);
    isa_ok($reln, "SReln::Compound");
    cmp_ok($reln->get_base_category(), 'eq', $S::ASCENDING);
    cmp_ok($reln->get_base_meto_mode(), 'eq', 1);
    cmp_ok( scalar( keys %{$reln->get_unchanged_bindings_ref()}), '==', 2);
    cmp_ok( scalar( keys %{$reln->get_changed_bindings_ref()}),   '==', 0);
    
    cmp_ok($reln->get_base_pos_mode(), 'eq', 1); # 1 is FWD
    cmp_ok($reln->get_position_reln()->get_text(), 'eq', "same");

    my $meto_reln = $reln->get_metonymy_reln;
    cmp_ok($meto_reln->get_change_ref()->{length}->get_text(), 'eq', 'succ');

    return; # skip
    my $new_object = apply_reln( $reln, $o1223b);
    $new_object->structure_ok([1,2,3]);

}


1;
