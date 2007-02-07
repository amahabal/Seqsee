use strict;
use blib;
use Test::Seqsee;
plan tests => 23; 

use Class::Multimethods;
multimethod 'find_reln';

SWorkspace->init({seq => [qw( 0 1 2 3 4 20 21 6)]});
my $WSO_ga = SAnchored->create($SWorkspace::elements[1], $SWorkspace::elements[2], $SWorkspace::elements[3], );
SWorkspace->add_group($WSO_ga);

my $rel_succ = find_reln($SWorkspace::elements[1], $SWorkspace::elements[2]);
my $rel_pred = find_reln($SWorkspace::elements[3], $SWorkspace::elements[2]);
dies_ok { $WSO_ga->set_underlying_reln($rel_pred) };
lives_ok { $WSO_ga->set_underlying_reln($rel_succ)};

my $underlying_reln = $WSO_ga->get_underlying_reln();
my $rule = $underlying_reln->get_rule();

sub SRuleApp::check_count{
    my ( $ruleapp, $count ) = @_;
    cmp_ok( scalar(@{$ruleapp->get_items()}), 'eq', $count, "count check");
}

isa_ok($underlying_reln, "SRuleApp");
$underlying_reln->check_count(3);

cmp_ok($WSO_ga->FindExtension($DIR::RIGHT, 0), 'eq', $SWorkspace::elements[4]);
$underlying_reln->check_count(3);
cmp_ok($WSO_ga->FindExtension($DIR::RIGHT, 1), 'eq', $SWorkspace::elements[3]);
$underlying_reln->check_count(3);
cmp_ok($WSO_ga->FindExtension($DIR::RIGHT, 2), 'eq', $SWorkspace::elements[2]);
$underlying_reln->check_count(3);
cmp_ok($WSO_ga->FindExtension($DIR::LEFT, 0), 'eq', $SWorkspace::elements[0]);
$underlying_reln->check_count(3);
cmp_ok($WSO_ga->FindExtension($DIR::LEFT, 1), 'eq', $SWorkspace::elements[1]);
$WSO_ga->get_underlying_reln()->check_count(3);

dies_ok {$WSO_ga->Extend($SWorkspace::elements[5], 1)};
lives_ok {$WSO_ga->Extend($SWorkspace::elements[4], 1)};
$WSO_ga->get_underlying_reln()->check_count(4);
cmp_ok($WSO_ga->FindExtension($DIR::RIGHT, 2), 'eq', $SWorkspace::elements[3]);
is_deeply( $WSO_ga->get_underlying_reln()->get_items(),
               [@SWorkspace::elements[1..4]]);

my $WSO_unstarred = SAnchored->create($SWorkspace::elements[5], $SWorkspace::elements[6], );
SWorkspace->add_group($WSO_unstarred);

my $meto = SMetonym->new({starred => SObject->create(5),
                          unstarred => $WSO_unstarred,
                          category  => "some_cat",
                          name      => "some_name",
                          info_loss => {},
                      });
$WSO_unstarred->SetMetonym($meto);
$WSO_unstarred->SetMetonymActiveness(1);

cmp_ok($WSO_ga->FindExtension($DIR::RIGHT, 0), 'eq', $WSO_unstarred);
$WSO_ga->Extend($WSO_unstarred, 1);
is_deeply( $WSO_ga->get_underlying_reln()->get_items(),
               [@SWorkspace::elements[1..4], $WSO_unstarred]);

my $bindings = $WSO_ga->describe_as($S::ASCENDING);
ok( $bindings, );
cmp_ok( $bindings->get_metonymy_mode(), 'eq', $METO_MODE::SINGLE);
