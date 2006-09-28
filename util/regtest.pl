use blib;
use Test::Seqsee;
use warnings;

my (@improved, @became_worse);
my @files = glob("Reg/seq_*.reg");

for $file (@files) {
    my ( $imp_ref, $worse_ref ) = RegHarness($file);
    push @improved,     @$imp_ref;
    push @became_worse, @$worse_ref;
}

if (@improved) {
    print "\nThe following improved:\n";
    for (@improved) {
        print "\tFrom $_->[1] to $_->[2]\n\t\t", join( ", ", @{ $_->[0] } ), "\n";
    }
}
if (@became_worse) {
    print "\nThe following became worse:\n";
    for (@became_worse) {
        print "\tFrom $_->[1] to $_->[2]\n\t\t", join( ", ", @{ $_->[0] } ), "\n";
    }
}

