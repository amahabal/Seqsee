use GraphViz;
use Data::Dump::Streamer;

use lib 'lib';
use SCF::All;
use SThought::All;
use Seqsee;
use SStream;

my $g = GraphViz->new(rankdir => 1,
                      width => 8,
                      height => 11,
                          );

{
    my $ACTION_PATTERN = qr{'SAction'->new\(\s*\{\s*'family'\s*,\s*['"](\w+)['"]};
    my $CODELET_PATTERN = qr{new SCodelet\(\s*"(\w+)"};
    my $CODELET_PATTERN2 = qr{'SCodelet'->new\(\s*['"](\w+)['"]};
    my $THOUGHT_PATTERN = qr{'SThought::(\w+)'->new};
    my $THOUGHT_PATTERN2 = qr{'SThought'->create\(};
    sub AddEdges{
        my ( $source_node, $code ) = @_;
        if ($source_node =~ /^SCF/) {
            $g->add_node($source_node, shape => 'trapezium', 
                             color => 'yellow', style => 'filled');
        } elsif ($source_node =~ /^SThought/) {
            $g->add_node($source_node, shape => 'octagon',
                             color => 'red', style => 'filled');
        } else {
            $g->add_node($source_node,
                         shape => 'triangle',
                         style => 'filled',
                         color => 'green',
                             )
        }
        #print $code;
        while ($code =~ m/$ACTION_PATTERN/g) {
            $g->add_edge($source_node, "SCF::$1");
            print "$source_node =>(a) $1\n";
        }
        while ($code =~ m/$CODELET_PATTERN/g) {
            $g->add_edge($source_node, "SCF::$1", style => 'dotted');
            print "$source_node =>(c) $1\n";
        }
        while ($code =~ m/$CODELET_PATTERN2/g) {
            $g->add_edge($source_node, "SCF::$1", style => 'dotted');
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

{ # SCF
    open my $in, "<", 'lib/SCF/All.pm';
    my @packages = map {m/ \[ package \] \s* (\S+)/x; $1 }
        grep { m/^ \s* \[ package \] /x } <$in>;
    close $in;
    for my $p (@packages) {
        # print "Package: $p\n";
        my $sub_name = $p . '::run';
        my $run_sub =             \&$sub_name;
        my $as_str = Dump($run_sub)->Out();
        # print $as_str;
        AddEdges($p, $as_str);
    }
}

{ # SThought
    open my $in, "<", 'lib/SThought/All.pm';
    my @packages = map {m/ \[ package \] \s* (\S+)/x; $1 }
        grep { m/^ \s* \[ package \] /x } <$in>;
    close $in;
    for my $p (@packages) {
        # print "Package: $p\n";
        my $sub_name = $p . '::get_actions';
        my $sub_ref =             \&$sub_name;
        my $as_str = Dump($sub_ref)->Out();
        # print $as_str; 
        AddEdges($p, $as_str);
    }
}

{ # Background activity
    my $sub_name = 'Seqsee::do_background_activity';
    my $sub_ref =             \&$sub_name;
    my $as_str = Dump($sub_ref)->Out();
    # print $as_str; 
    AddEdges("Background", $as_str);
}

{ # Stream activity
    my $sub_name = 'SStream::_think_the_current_thought';
    my $sub_ref =             \&$sub_name;
    my $as_str = Dump($sub_ref)->Out();
    # print $as_str; 
    AddEdges("Stream", $as_str);
}

open my $OUT, ">", 'graph.ps';
binmode $OUT;
print {$OUT} $g->as_ps;
close $OUT;

