use strict;
use blib;
use Test::Seqsee;
plan tests => 11; 

use Class::Multimethods qw(find_reln);
use Class::Multimethods qw(are_relns_compatible);
use Class::Multimethods qw(apply_reln);
use Class::Multimethods qw(plonk_into_place);

SWorkspace->init({seq => [qw( 1 1 2 2 3 3 4 4)]});

my $WSO_ra = find_reln($SWorkspace::elements[0], $SWorkspace::elements[1]);
$WSO_ra->insert();

my $WSO_rb = find_reln($SWorkspace::elements[2], $SWorkspace::elements[3]);
$WSO_rb->insert();

my $WSO_rc = find_reln($SWorkspace::elements[4], $SWorkspace::elements[5]);
$WSO_rc->insert();
 
my $WSO_rd = find_reln($SWorkspace::elements[6], $SWorkspace::elements[7]);
$WSO_rd->insert();
 
my $WSO_ga = SAnchored->create($SWorkspace::elements[0], $SWorkspace::elements[1], );
SWorkspace->add_group($WSO_ga);
$WSO_ga->set_underlying_reln($WSO_ra);

my $WSO_gb = SAnchored->create($SWorkspace::elements[2], $SWorkspace::elements[3], );
SWorkspace->add_group($WSO_gb);
$WSO_gb->set_underlying_reln($WSO_rb);

my $WSO_gc = SAnchored->create($SWorkspace::elements[4], $SWorkspace::elements[5], );
SWorkspace->add_group($WSO_gc);
$WSO_gc->set_underlying_reln($WSO_rc);

my $WSO_gd = SAnchored->create($SWorkspace::elements[6], $SWorkspace::elements[7], );
SWorkspace->add_group($WSO_gd);
$WSO_gd->set_underlying_reln($WSO_rd);

dies_ok { my $WSO_re = find_reln($WSO_ga, $WSO_gb);
          $WSO_re->insert();
       };

$WSO_ga->describe_as( $S::SAMENESS );
$WSO_gb->describe_as( $S::SAMENESS );
$WSO_gc->describe_as( $S::SAMENESS );
$WSO_gd->describe_as( $S::SAMENESS );


my $WSO_re = find_reln($WSO_ga, $WSO_gb);
$WSO_re->insert();
 
ok( UNIVERSAL::isa($WSO_re, "SReln") , );
ok( exists $SWorkspace::relations{$WSO_re}, );
ok( UNIVERSAL::isa($WSO_ga, "SAnchored") , );

ok( UNIVERSAL::isa($WSO_re, "SReln::Compound") , );

ok( $WSO_re->get_base_category() eq $S::SAMENESS, );
ok( $WSO_re->get_base_meto_mode() eq METO_MODE::NONE(), );
ok( $WSO_re->get_unchanged_bindings_ref()->{length} eq 2, );
ok( UNIVERSAL::isa( $WSO_re->get_changed_bindings_ref()->{each}, "SReln::Simple") );
ok( $WSO_re->get_first() eq $WSO_ga, );
ok( $WSO_re->get_second() eq $WSO_gb, );


