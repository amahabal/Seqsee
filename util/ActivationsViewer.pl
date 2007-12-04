use strict;
use Tk;
use Carp;
use Smart::Comments;
use Getopt::Long;
use List::Util qw(sum);
my %options;

my $filename = 'activations.log';
my %Id2Names;
my %Names2Id;
my @TimesWhenSampled;
my %Activations; # keys: ids. Values: { time => activation, time => activation, ...}
ReadFile($filename);

my $MW = new MainWindow();
$MW->focusmodel('active');
$MW->bind(
    '<KeyPress-q>' => sub {
        exit;
    }
);
my $frame = $MW->Frame()->pack( -side => 'top' );
my $combo1 = $frame->ComboEntry(
    -itemlist => [ sort keys %Names2Id ],
    -width    => 60,
)->pack( -side => 'left' );
$frame->Button(
    -text    => 'Show',
    -command => sub {
        ShowGraph( $combo1->get() );
        }

)->pack( -side => 'left' );

my $Canvas = $MW->Canvas( -height => 300, -width => 700 )->pack( -side => 'top' );
MainLoop;


sub ReadFile {
    my ( $filename ) = @_;
    open my $IN, '<', $filename or die "Failed to open >>$filename<<";
    while (my $line = <$IN>) {
        chomp($line);
        if ($line =~ m#^NewNode\s+(\d+)\s+(.*)#x) {
            $Id2Names{$1}=$2;
            $Names2Id{$2}=$1;
        } elsif ($line =~ m#^\d+#) {
            my ($time, %activations) = split(/\s+/, $line);
            push @TimesWhenSampled, $time;
            while (my($k, $v) = each %activations) {
                $Activations{$k}{$time} = $v;
            }
        }
    }
}

sub ShowGraph {
    my ($node) = @_;
    my %data = %{$Activations{$Names2Id{$node}}};

    $Canvas->delete('all');
    $Canvas->create( 'rectangle', 10, 10, 690, 290 );
    my $maximum_timestamp = $TimesWhenSampled[-1];
    my $width_per_timestep = 680 / $maximum_timestamp;
    while (my($time, $value) = each %data) {
        my $x = 10 + $time * $width_per_timestep;
        my $y = 290 - 280 * $value;
        $Canvas->create('line', $x, $y, $x, 290, -fill=>'#0000FF');
    }
}
