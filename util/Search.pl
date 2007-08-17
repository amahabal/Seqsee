use strict;
use File::Slurp qw(slurp);
my $what = $ARGV[0];

my $subroutine_re = qr{^\s*sub\s};

my $locations = <<LOCATIONS;
lib/*.pm
lib/*/*.pm
lib/*/*/*.pm

LOCATIONS

use Tk;
my $MW = new MainWindow();
my $frame = $MW->Frame()->pack( -side => 'top' );
$frame->Entry( -textvariable => \$what )->pack( -side => 'left' );
$frame->Button(
    -text    => 'Search',
    -command => sub {
        Search($what);

    }
)->pack( -side => 'left' );

my $TB = $MW->Scrolled('Text')->pack();
$TB->tagConfigure( 'file', -background => '#FFCCCC' );
$TB->tagConfigure( 'sub',  -background => '#CCCCFF' );
Search();
MainLoop();

sub Search {
    return unless $what;
    $TB->delete('0.0', 'end');
    my $re = qr{$what};
    for my $file ( glob($locations) ) {
        my $content = slurp($file);
        if ( $content =~ $re ) {

            #print "File: $file\n";
            $TB->insert( 'end', $file, ['file'], "\n" );
            open my $IN, '<', $file;
            my $counter;
            my $most_recent_sub;
            my $match_found_since_last_sub;
            while ( my $line = <$IN> ) {
                $line =~ s#^\s*##;
                if ( $line =~ $subroutine_re ) {
                    $most_recent_sub = $line;
                    chomp($most_recent_sub);
                    $match_found_since_last_sub = 0;
                }
                next unless $line =~ $re;

                $counter++;
                if ( !$match_found_since_last_sub ) {

                    #print "\n", " " x 4, "." x 20, "\n";
                    #print " " x 4, "$most_recent_sub";
                    $TB->insert( 'end', " " x 4, [], $most_recent_sub, ['sub'], "\n" );
                }
                $match_found_since_last_sub = 1;

                #print " " x 8, "$line";
                $TB->insert( 'end', " " x 8, [], $line, [], "\n" );

            }
            print "\n\n";
            close($IN);
        }
    }
}
