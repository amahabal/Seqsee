use Test::More tests => 33;
use Test::MockObject;
use blib;

use STestInit;

Test::MockObject->fake_module('SThought');

BEGIN {use_ok('SStream')};

# We shall mock a few thoughts:
my $t1 = Test::MockObject->new();
$main::__first_call = 0;
$t1->mock('components', 
	  sub { 
	    unless ($main::__first_call) 
		  {
		    $main::__first_call = 1;
		    return(1,2,3)
		  };
		return (7,8,9);
	      }
	 );
my $t2 = Test::MockObject->new();
$t2->mock('components', sub { return(2) } );
my $t3 = Test::MockObject->new();
$t3->mock('components', sub { return(4,5) } );

$t1->mock('contemplate', sub{});
$t2->mock('contemplate', sub{});
$t3->mock('contemplate', sub{});

can_ok('SStream', qw{ Reset 
		      maybe_expell_thoughts
		      antiquate_thought
		      add_thought new_thought
		      recalculate_CompStrength
		   });

#ensure that the delta value is set: 
$SStream::DiscountFactor = 0.8;
$SStream::ThoughtCount   = 0;
$SStream::MaxThoughts    = 10;
SStream->antiquate_thought();
cmp_ok($SStream::ThoughtCount, '==', 0);

ok(not(defined $SStream::CurrentThought), "No current thought at start");

SStream->new_thought($t1);
cmp_ok($SStream::CurrentThought, 'eq', $t1);
cmp_ok($SStream::ThoughtCount, '==', 0);
cmp_ok(scalar(@SStream::Thoughts), '==', 0);
ok(exists($SStream::ThoughtsList{$t1}), "Current thought in thoughtlist" );

SStream->antiquate_thought;
ok(not(defined $SStream::CurrentThought), "antiquate undefines current");
cmp_ok($SStream::ThoughtCount, '==', 1);
cmp_ok(scalar(@SStream::Thoughts), '==', 1);

cmp_ok($SStream::CompStrength{1}, '==', 0.8);
SStream->new_thought($t2);
ok(not (defined $t2->{str_comps}), "str_comps snapshot does not happen too soon");
ok(exists($SStream::ThoughtsList{$t2}), "Current thought in thoughtlist" );

SStream->new_thought($t3);
cmp_ok($SStream::ThoughtCount, '==', 2);
cmp_ok(scalar(@SStream::Thoughts), '==', 2);
cmp_ok($SStream::CompStrength{1}, 'eq',  0.64);
cmp_ok($SStream::CompStrength{2}, 'eq', 1.44);

$SStream::MaxThoughts = 1;
SStream->maybe_expell_thoughts();
cmp_ok($SStream::ThoughtCount, '==', 1);
cmp_ok(scalar(@SStream::Thoughts), '==', 1);
cmp_ok($SStream::CompStrength{1},'==',  0);
cmp_ok($SStream::CompStrength{2}, '==', 0.8);
ok(not (exists $SStream::ThoughtsList{$t1}), 
   "Explelled thought not in thoughtlist" );

SStream->new_thought($t3); # That is the current thought!
# Nothing changes...
cmp_ok($SStream::CurrentThought, 'eq', $t3);
cmp_ok($SStream::ThoughtCount, '==', 1);

$SStream::MaxThoughts = 10;
SStream->new_thought($t1); # Now with 7,8,9!
# components are and curr:t1=[789] old: t3=[45] t2=[2]
cmp_ok($SStream::CurrentThought, 'eq', $t1);
cmp_ok($SStream::Thoughts[0], 'eq', $t3);
cmp_ok($SStream::CompStrength{2}, 'eq', 0.64);

SStream->new_thought($t3); # That thought is an old thought.
# components are and curr:t3=[45] old: t1=[789] t2=[2] 
cmp_ok($SStream::CurrentThought, 'eq', $t3);
cmp_ok($SStream::Thoughts[0], 'eq', $t1);
cmp_ok($SStream::Thoughts[0]->{str_comps}[0], '==', 7);
cmp_ok($SStream::CompStrength{2}, 'eq', 0.64);
cmp_ok($SStream::CompStrength{7}, 'eq', 0.8);
