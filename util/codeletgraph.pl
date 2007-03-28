use GraphViz;
my $g = GraphViz->new(rankdir => 1,
                      width => 5,
                      height => 8,
                          );

{
    my $ACTION_PATTERN = qr{SAction->new\(\s*\{\s*family\s*=>\s*"(\w+)"};
    my $CODELET_PATTERN = qr{new SCodelet\(\s*"(\w+)"};
    my $CODELET_PATTERN2 = qr{SCodelet->new\(\s*"(\w+)"};
    my $THOUGHT_PATTERN = qr{SThought::(\w+)->new};
    my $THOUGHT_PATTERN2 = qr{SThought->create\(};
    sub AddEdges{
        my ( $source_node, $code ) = @_;
        if ($source_node =~ /^SCF/) {
            $g->add_node($source_node, shape => 'trapezium', 
                             color => 'yellow', style => 'filled');
        } elsif ($source_node =~ /^SThought/) {
            $g->add_node($source_node, shape => 'octagon',
                             color => 'red', style => 'filled');
        } else {
            die "huh? '$source_node'";
        }
        #print $code;
        while ($code =~ m/$ACTION_PATTERN/g) {
            $g->add_edge($source_node, "SCF::$1");
            print "$source_node =>(a) $1\n";
        }
        while ($code =~ m/$CODELET_PATTERN/g) {
            $g->add_edge($source_node, "SCF::$1");
            print "$source_node =>(c) $1\n";
        }
        while ($code =~ m/$CODELET_PATTERN2/g) {
            $g->add_edge($source_node, "SCF::$1");
            print "$source_node =>(c) $1\n";
        }
        while ($code =~ m/$THOUGHT_PATTERN/g) {
            $g->add_edge($source_node, "SThought::$1");
            print "$source_node =>(t) $1\n";
        }
        while ($code =~ m/$THOUGHT_PATTERN2/g) {
            $g->add_edge($source_node, "SThought::??");
            print "$source_node =>(t) (create)\n";
        }
    }
}

sub ProcessFile{
    my ( $filename ) = @_;
    open my $IN, "<", $filename or die "Could not open $filename";
    my $package;
    my $last_package;
    my $package_block;
    while (my $line = <$IN>) {
        if ($line =~ m/package\s+(\S+)\s*;/o) {
            $last_package = $package;
            $package = $1;
            AddEdges($last_package, $package_block) if $last_package;
            $package_block = '';
        } else {
            $package_block .= $line;
        }
    }
    AddEdges($package, $package_block);
}

ProcessFile('lib/SThought/All.pmc');
ProcessFile('lib/SCF/All.pmc');

open my $OUT, ">", 'graph.ps';
binmode $OUT;
print {$OUT} $g->as_ps;
close $OUT;

