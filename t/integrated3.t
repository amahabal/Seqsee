use strict;
use blib;
use Test::Seqsee;
use Smart::Comments;
plan tests => 10; 

use Class::Multimethods qw(find_reln);
use Class::Multimethods qw(are_relns_compatible);
use Class::Multimethods qw(apply_reln);
use Class::Multimethods qw(plonk_into_place);

SWorkspace->init({seq => [qw( 1 1 2 3 1 2 2 3)]});

my $WSO_ra = find_reln($SWorkspace::elements[0], $SWorkspace::elements[1]);
$WSO_ra->insert();

my $WSO_ga = SAnchored->create($SWorkspace::elements[0], $SWorkspace::elements[1], );
SWorkspace->add_group($WSO_ga);
 
$WSO_ga->describe_as($S::SAMENESS);

dies_ok { $WSO_ga->set_metonym_activeness(1);};

$WSO_ga->annotate_with_metonym( $S::SAMENESS, "each");
my $WSO_ma = $WSO_ga->get_metonym();
## $WSO_ma
isa_ok( $WSO_ma, "SMetonym");
ok( $WSO_ma->get_category() eq $S::SAMENESS, );
ok( $WSO_ma->get_name() eq "each", );
ok( UNIVERSAL::isa($WSO_ma->get_starred(), "SElement"), );
ok( $WSO_ma->get_unstarred() eq $WSO_ga, );

ok( not($WSO_ga->get_metonym_activeness()), );
ok( not(find_reln($WSO_ga, $SWorkspace::elements[2])), );

lives_ok { $WSO_ga->set_metonym_activeness(1);};

my $WSO_rb = find_reln($WSO_ga, $SWorkspace::elements[2]);
$WSO_rb->insert();
 





