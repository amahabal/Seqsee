use strict;
use Tk;
use Carp;
use Smart::Comments;

my $filename = 'codelet_tree.log';

our %CreatedAtPosition;
our %ExecutedAtPosition;
our %Progeny;
our %Parent;
our @ExecuteOrder;
our @CreationOrder;
our %Details;
our %AlreadyPrinted;
our %SeenCount;

my $MW = new MainWindow();
$MW->focusmodel('active');
my $text = $MW->Scrolled(
    'Text',
    -scrollbars => 'se',
    -width      => 100,
    -height     => 40,
)->pack( -side => 'bottom' );
$text->focus();
$text->tagConfigure( 'was_executed', );
$text->tagConfigure( 'wasnt_executed', -overstrike => 1 );
$text->tagConfigure( 'Codelet',        -background => '#FFAAAA' );
$text->tagConfigure( 'Action',         -background => '#AAFFAA' );
$text->tagConfigure( 'Thought',        -background => '#AAAAFF' );
$MW->bind(
    '<KeyPress-q>' => sub {
        exit;
    }
);

my $counter_of_executions = 0;
Phase_One();
Phase_Two();
my %ObjectTypesSeen;
while ( my ( $k, $v ) = each %Details ) {
    my $v_copy = $v;
    $v_copy =~ s#^\s*(\S+).*#$1#;
    if ( $k =~ /^SThought::([^=]*)/i ) {
        $ObjectTypesSeen{$1} = 'Thought';
    }
    else {
        $ObjectTypesSeen{$v_copy} = 'Codelet';
    }
}
## ObjectTypesSeen: %ObjectTypesSeen
my $frame = $MW->Frame()->pack( -side => 'top' );
$frame->ComboEntry(
    -itemlist => [ grep { $ObjectTypesSeen{$_} eq 'Thought' } keys %ObjectTypesSeen ],
    -width => 40,
)->pack( -side => 'left' );
$frame->ComboEntry(
    -itemlist => [ grep { $ObjectTypesSeen{$_} ne 'Thought' } keys %ObjectTypesSeen ],
    -width => 40
)->pack( -side => 'left' );
MainLoop();

sub Phase_One {
    open my $file, '<', $filename;
    my $parent;
    while ( my $line = <$file> ) {
        chomp($line);
        if ( $line =~ /^Initial/ or $line =~ /^Background/ ) {
            $parent = '';
        }
        elsif ( $line =~ /^\S+ \s* (\S+)/x ) {
            my $object = $1;
            if ( exists $SeenCount{$object} ) {

                #print "$object ====> " , $SeenCount{$object}, "\n";
                $object .= "#$SeenCount{$object}";
            }
            push @ExecuteOrder, $object;
            $ExecutedAtPosition{$object} = $counter_of_executions;
            $parent = $object;
            $counter_of_executions++;
        }
        else {
            $line =~ /^ \s+ (\S+) \s* (.*) /x;
            my ( $object, $details ) = ( $1, $2 );
            if ( exists $Details{$object} ) {
                $SeenCount{$object}++;
                $object .= "#$SeenCount{$object}";
            }
            $CreatedAtPosition{$object} = $counter_of_executions;
            push @{ $CreationOrder[$counter_of_executions] }, $object;
            $Details{$object} = $details;
            if ($parent) {
                push @{ $Progeny{$parent} }, $object;
            }
            $Parent{$object} = $parent;
        }
    }
}

sub Phase_Two {
    for my $idx ( 0 .. $counter_of_executions - 1 ) {
        my $object = $ExecuteOrder[$idx];
        PrintProgeny( $object, 0 ) unless $AlreadyPrinted{$object};

        for ( @{ $CreationOrder[$idx] || [] } ) {
            PrintProgeny( $_, 0 ) if ( !exists( $ExecutedAtPosition{$_} ) and !$Parent{$_} );
        }

    }
}

sub CreateDisplay {
    my ( $object, $execute_position, $details ) = @_;
    my $executed_tag = defined($execute_position) ? "was_executed" : "wasnt_executed";
    $execute_position = sprintf( '% 5d', $execute_position ) if defined($execute_position);

    my $creation_position = sprintf( '% 5d', $CreatedAtPosition{$object} - 1 );
    my @position_text = defined($execute_position)
        ? ( "[$creation_position/$execute_position] ", ['execute_position'] )
        : ( "[$creation_position/xxxxx]", "wasnt_executed" );
    if ( $object =~ /^SCodelet=ARRAY/ ) {
        return ( @position_text, "Codelet $details", [ 'Codelet', $executed_tag ] );
    }
    elsif ( $object =~ /^SAction=SCALAR/ ) {
        return ( @position_text, "Action $details", [ 'Action', $executed_tag ] );
    }
    elsif ( $object =~ /^SThought::(.*?)=/ ) {
        return ( @position_text, "$1", [ 'Thought', $executed_tag ] );
    }
    else {
        confess("Funny object >$object<");
    }
}

sub PrintProgeny {
    my ( $object, $depth ) = @_;

    my $execute_position = $ExecutedAtPosition{$object};

    $text->insert( 'end', q{   } x $depth,
        '', CreateDisplay( $object, $execute_position, $Details{$object} ), "\n" );

    $AlreadyPrinted{$object} = 1;
    my @progeny = @{ $Progeny{$object} || [] };
    for (@progeny) {
        PrintProgeny( $_, $depth + 1 );
    }
}

