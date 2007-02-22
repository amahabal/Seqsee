use strict;
use blib;
use Test::Seqsee;
plan tests => 7; 
use Class::Multimethods;
use Smart::Comments;

multimethod 'find_reln';

BEGIN {
  use_ok "SCat::reln_based";
}

my $cat = $S::RELN_BASED;
isa_ok( $cat, "SCat::OfObj" );

IS_INSTANCE: {
    SWorkspace->init({seq => [qw( 1 1 2 2)]});
    my $WSO_ra = find_reln($SWorkspace::elements[0], $SWorkspace::elements[1]);
    $WSO_ra->insert();
    my $WSO_ga = SAnchored->create($SWorkspace::elements[0], $SWorkspace::elements[1], );
    SWorkspace->add_group($WSO_ga);
     
    my $bindings;
    $bindings = $cat->is_instance( $WSO_ga );
    ## $bindings
    ok( not($bindings), );

    $WSO_ga->set_underlying_reln( $WSO_ra );
    $bindings = $cat->is_instance( $WSO_ga );
    ## $bindings
    {
        local $TODO = 1;
        cmp_ok( $bindings->GetBindingForAttribute('relation'), 'eq', $WSO_ra );
    }
    $bindings = $cat->is_instance( $SWorkspace::elements[0]);
    ok( not($bindings), );
}

BLEMISHED_IS_INST: {
    SUtil::clear_all();
    SWorkspace->init({seq => [qw( 1 1 2 3)]});

    my $WSO_ra = find_reln($SWorkspace::elements[0], $SWorkspace::elements[1]);
    $WSO_ra->insert();
     
    my $WSO_ga = SAnchored->create($SWorkspace::elements[0], $SWorkspace::elements[1], );
    SWorkspace->add_group($WSO_ga);
    $WSO_ga->AnnotateWithMetonym($S::SAMENESS, 'each');
    $WSO_ga->SetMetonymActiveness(1);

    my $WSO_rb = find_reln($WSO_ga, $SWorkspace::elements[2]);
    $WSO_rb->insert();
    my $WSO_gb = SAnchored->create($WSO_ga, $SWorkspace::elements[2], $SWorkspace::elements[3], );
    SWorkspace->add_group($WSO_gb);
     
    $WSO_gb->set_underlying_reln($WSO_rb);

    my $bindings;
    
    $bindings =
        $cat->is_instance( $WSO_gb );
    ok( not($bindings), );

    ## here
    my $WSO_rc = find_reln($SWorkspace::elements[2], $SWorkspace::elements[3]);
    $WSO_rc->insert();
    $bindings =
        $cat->is_instance( $WSO_gb );
    ok( $bindings, );

    ok( $bindings->get_metonymy_mode() eq METO_MODE::SINGLE(), );


}

