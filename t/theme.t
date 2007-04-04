use strict;
use blib;
use Test::Seqsee;
plan tests => 1; 

use Themes::Std;
lives_ok { Style::Element() };
my %e_style =Style::Element();
print $e_style{-fill};
