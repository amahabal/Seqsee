use strict;
use Tk;
use lib 'genlib';
use Test::Seqsee;

my ( $times, $terms ) = @ARGV;

my $MW = new MainWindow();

my $Text = $MW->Text( -width => 130 )->pack();
$Text->tagConfigure( 'success',   -background => 'blue',   -foreground => 'white' );
$Text->tagConfigure( 'error',     -background => 'red',    -foreground => 'white' );
$Text->tagConfigure( 'nosuccess', -background => 'yellow', -foreground => 'white' );

$Text->insert('end', "Please wait....");
$Text->update();

StartRun();

$MW->MainLoop();

sub StartRun {
    my ( $imp_ref, $worse_ref, $results_ref, $opts_ref )
        = RegHarness( { seq => $terms, max_steps => 20000 } );

    my $seq = join( ', ', @{ $opts_ref->{seq} } );
    ### results: $results_ref
    ### opts_ref: $opts_ref
    ### seq: $seq
    Update($results_ref);
}

sub Update {
    my $results_ref = shift;
    $Text->delete( '0.0', 'end' );
    Display_Selected( $results_ref );
    $MW->update();
}

sub find_tag {
    my ($msg) = @_;
    if ( $msg =~ /^SUCCESS/ ) {
        return ["success"];
    }
    elsif ( $msg =~ /^Error/ ) {
        return ["error"];
    }
    else {
        return ["nosuccess"];
    }
}

sub Display_Selected {
    my ($arr_ref) = @_;
    my @arr = @$arr_ref;

    my @string = map { ( "X", find_tag($_) ) } @arr;
    $Text->insert( 'end', @string, "\n" );

    for my $line (@arr) {
        ### line: $line
        $Text->insert( 'end', "======\n\n" );
        $Text->insert( 'end', $line, '', "\n" );
    }
}

