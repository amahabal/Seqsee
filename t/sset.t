use strict;
use lib 'genlib';
use Test::Seqsee;
BEGIN { plan tests => 4; }

my $set = new SSet;

$set->insert('a', 'b', 'c');

is scalar($set->members), 3;
ok $set->is_member('a');

my $x = bless { a => 3}, "Foo";
$set->insert( $x );
ok $set->is_member($x);

my @ref_members = grep { ref $_ } $set->members;
is $ref_members[0]->{a}, 3;
