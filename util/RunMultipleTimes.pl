use strict;
use Tk;
use lib 'genlib';
use Test::Seqsee;

my ( $times, $terms ) = @ARGV;

my $TIMES_TO_RUN = 10;

my $MW = new MainWindow();

my $Text = $MW->Text( -width => 130 )->pack();
$Text->tagConfigure( 'success',   -background => 'blue',   -foreground => 'white' );
$Text->tagConfigure( 'error',     -background => 'red',    -foreground => 'white' );
$Text->tagConfigure( 'nosuccess', -background => 'yellow', -foreground => 'white' );

$Text->insert( 'end', "Please wait...." );
$Text->update();
my @RESULTS;

StartRun();

$MW->MainLoop();

use Storable;

sub StartRun {
    my ( $seq, $continuation ) = split( /\|/, $terms );
    my @cmd = (
        'c:\perl\bin\perl',   'util/RunTestOnce.pl',
        qq{--seq="$seq"},     qq{--continuation="$continuation"},
        qq{-max_steps=10000}, qq{--min_extension=3},
        qq{--max_false=3}
    );

    # my $cmd = join(" ", @cmd);
    for ( 1 .. $TIMES_TO_RUN ) {
        print ">>@cmd<<\n";
        system @cmd;
        open( my $RESULT, '<', "foo" ) or confess "Unable to open file >>foo<<";
        my $result_str        = join('', <$RESULT>);
        my $result_object = Storable::thaw($result_str) or confess "Unable to thaw: >>$result_str<<!!";
        push @RESULTS, $result_object;
        Update();
    }
}

sub Update {
    if (@RESULTS) {
        $Text->delete( '0.0', 'end' );
        my @top_row = map { find_tag( $_->get_status() ) } @RESULTS;
        $Text->insert( 'end', @top_row, scalar(@RESULTS), '', "/$TIMES_TO_RUN", '', "\n" );
        for (@RESULTS) {
            $Text->insert( 'end', "\n............\n", '',  find_tag( $_->get_status() ),
                "\t", '', $_->get_steps(), '', "\n\n" );
            $Text->insert('end', $_->get_error()) if $_->get_error();
        }
        $MW->update();
    }
}

sub find_tag {
    my ($status) = @_;
    print $status;
    if ( $status->IsSuccess() ) {
        return ( "O", ["success"] );
    }
    elsif ( $status->IsACrash() ) {
        return ( " CRASH! ", ["error"] );
    }
    elsif ( $status->IsAtLeastAnExtension() ) {
        return ( "?", ["success"] );
    }
    else {
        return ( "X", ["nosuccess"] );
    }
}

sub Display_Selected {
    my ($arr_ref) = @_;
    my @arr = @$arr_ref;

    my @string = map { ( " X ", find_tag($_) ) } @arr;
    $Text->insert( 'end', @string, " \n " );

    for my $line (@arr) {
        ### line: $line
        $Text->insert( 'end', " == == == \n \n " );
        $Text->insert( 'end', $line, '', " \n " );
    }
}

