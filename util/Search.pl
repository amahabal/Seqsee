use strict;
use File::Slurp qw(slurp);
my $what = $ARGV[0] or die "Need argument";

my $locations = <<LOCATIONS;
lib/*.pm
lib/*/*.pm
lib/*/*/*.pm

LOCATIONS

my $re = qr{$what};
for my $file (glob($locations)) {
    my $content = slurp($file);
    if ($content =~ $re) {
        print "File: $file\n";
        open my $IN, '<', $file;
        my $counter;
        while (my $line = <$IN>) {
            next unless $line =~ $re;
            $counter++;
            print "\t$counter. $line";
        }
        print "\n\n";
        close($IN);
    }
}
