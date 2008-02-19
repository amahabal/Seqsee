use 5.10.0;
use Tk;
use Smart::Comments;

use constant { WIDTH => 500, HEIGHT => 100, PAGEHEIGHT => '3c' };
use constant {
    ARROW_LEFT           => 100,
    ARROW_33             => 200,
    ARROW_66             => 300,
    ARROW_RIGHT          => 400,
    ARROW_LABEL_Y_OFFSET => 3,
    RIGHT_END_OF_FIRST   => 80,
    LEFT_END_OF_SECOND   => 420,
        RIGHT_END_OF_LABEL => 380,
};
my ( $CATEGORY, $DESCRIPTORS_COUNT, $FIRST_OBJECT_DESCRIPTION_TB, %FIRST_OBJECT_DESCRIPTION,
    $SECOND_OBJECT_DESCRIPTION_TB, %SECOND_OBJECT_DESCRIPTION, $CANVAS, );

my $DIR = 'D:/DISSERTATION/Chapters/RelationEPS';
my $FILENAME;

my $MW = new MainWindow();
$MW->bind(
    '<KeyPress-q>' => sub {
        exit;
    }
);
$MW->bind(
    '<F1>' => \&Draw,
);
$MW->bind(
    '<F10>' => \&Save,
);
$MW->focusmodel('active');

#====
my $button = $MW->Button(
    -text    => 'Draw',
    -command => \&Draw,
)->pack( -side => 'top' );
$button->focus();
{
    my $f = $MW->Frame()->pack( -side => 'top' );
    $f->Label( -text => 'Category' )->pack( -side => 'left' );
    $f->Entry( -textvariable => \$CATEGORY )->pack( -side => 'left' );
}
{
    my $f = $MW->Frame()->pack( -side => 'top' );
    $f->Label( -text => 'Descriptors' )->pack( -side => 'left' );
    $f->Entry( -textvariable => \$DESCRIPTORS, -width => 100 )->pack( -side => 'left' );
}
{
    my $f = $MW->Frame()->pack( -side => 'top' );
    $f->Label( -text => 'First' )->pack( -side => 'left' );
    $FIRST_OBJECT_DESCRIPTION_TB
        = $f->Text( -height => 10, -width => 100 )->pack( -side => 'left' );
}

{
    my $f = $MW->Frame()->pack( -side => 'top' );
    $f->Label( -text => 'Second' )->pack( -side => 'left' );
    $SECOND_OBJECT_DESCRIPTION_TB
        = $f->Text( -height => 10, -width => 100 )->pack( -side => 'left' );
}

$CANVAS = $MW->Canvas( -height => HEIGHT(), -width => WIDTH(), -background => 'white' )
    ->pack( -side => 'top' );

{
    my $f = $MW->Frame()->pack( -side => 'top' );
    $f->Label( -text => 'Filename' )->pack( -side => 'left' );
    $f->Entry( -textvariable => \$FILENAME, -width => 100 )->pack( -side => 'left' );
}
$DESCRIPTORS = "start, end, length";
$CATEGORY    = "Ascending";
$FIRST_OBJECT_DESCRIPTION_TB->insert( 'end',  "start: 6\nend: 8\n length : 3" );
$SECOND_OBJECT_DESCRIPTION_TB->insert( 'end', "start:9:end:successor\nlength:7:end:pred" );

MainLoop();

sub trim {
    for (@_) {
        s#^\s*##;
        s#\s*$##;
        s#\s+# #g;
    }
    return @_;
}

sub Draw {
    $CANVAS->delete('all');
    my @descriptors = split( ",", $DESCRIPTORS );
    trim(@descriptors);

    $DESCRIPTORS_COUNT = scalar(@descriptors);

    my %descriptor_to_index;
    my $count = 0;
    for (@descriptors) {
        $descriptor_to_index{$_} = $count++;
    }

    my %firstobj_descriptions = ParseFirstObject( $FIRST_OBJECT_DESCRIPTION_TB->get( '0.0', 'end' ),
        \%descriptor_to_index );
    ### firstobj_descriptions: %firstobj_descriptions
    my %secondobj_descriptions
        = ParseSecondObject( $SECOND_OBJECT_DESCRIPTION_TB->get( '0.0', 'end' ),
        \%descriptor_to_index );
    ### secondobj_descriptions: %secondobj_descriptions

    for my $index ( 0 .. $DESCRIPTORS_COUNT - 1 ) {
        my $descriptor = $descriptors[$index];
        ### descriptor: $descriptor
        my $y_coordinate = index_to_y_coordinate($index);
        if ( $descriptor ~~ %firstobj_descriptions ) {
            $CANVAS->createText(
                 RIGHT_END_OF_FIRST(), $y_coordinate,
                -text   => "$descriptor=$firstobj_descriptions{$descriptor}",
                -anchor => 'e',
            );
        }
        if ( $descriptor ~~ %secondobj_descriptions ) {
            $CANVAS->createText(
                 LEFT_END_OF_SECOND(), $y_coordinate,
                -text   => "$descriptor=$secondobj_descriptions{$descriptor}",
                -anchor => 'w',
            );
        }
    }

    my @arrows
        = ParseArrows( $SECOND_OBJECT_DESCRIPTION_TB->get( '0.0', 'end' ), \%descriptor_to_index );
    for (@arrows) {
        DrawArrow(@$_);
    }

    GenerateFilename();
}

sub DrawArrow {
    my ( $from_index, $to_index, $relation ) = @_;
    ### draw_arr: @_
    my $y1 = index_to_y_coordinate($from_index);
    my $y2 = index_to_y_coordinate($to_index);
    $CANVAS->createLine( ARROW_LEFT(), $y1, ARROW_33(), $y1, ARROW_66(), $y2, ARROW_RIGHT(), $y2, -arrow => 'last' );
    $CANVAS->createText( RIGHT_END_OF_LABEL(), $y2 - ARROW_LABEL_Y_OFFSET(),
                         -text => $relation, -anchor => 'se',
                             );
}

sub ParseFirstObject {
    my ( $text, $descriptor_to_index_ref ) = @_;
    my @lines = split( "\n", $text );
    trim(@lines);

    my %description;
    for (@lines) {
        my ( $descriptor, $value ) = split( /:/, $_, 2 );
        trim( $descriptor, $value );
        say "Descriptor $descriptor non-existant!"
            unless exists $descriptor_to_index_ref->{$descriptor};
        $description{$descriptor} = $value;
    }
    return %description;
}

sub ParseSecondObject {
    my ( $text, $descriptor_to_index_ref ) = @_;
    my @lines = split( "\n", $text );
    trim(@lines);
    my %description;
    for (@lines) {
        my ( $descriptor, $value, $from_descriptor, $relation ) = split( /:/, $_, 4 );
        trim( $descriptor, $value );
        say "Descriptor $descriptor non-existant!"
            unless exists $descriptor_to_index_ref->{$descriptor};
        $description{$descriptor} = $value;
    }
    return %description;
}

sub ParseArrows {
    my ( $text, $descriptor_to_index_ref ) = @_;
    my @lines = split( "\n", $text );
    trim(@lines);
    my @arrows;
    for (@lines) {
        my ( $descriptor, $value, $from_descriptor, $relation ) = split( /:/, $_, 4 );
        trim( $descriptor, $value, $from_descriptor, $relation );
        say "Descriptor $descriptor non-existant!"
            unless exists $descriptor_to_index_ref->{$descriptor};
        say "Descriptor $from_descriptor non-existant!"
            unless exists $descriptor_to_index_ref->{$from_descriptor};
        push @arrows,
            [
            $descriptor_to_index_ref->{$from_descriptor}, $descriptor_to_index_ref->{$descriptor},
            $relation
            ];
    }
    return @arrows;
}

sub index_to_y_coordinate {
    my ($index) = @_;
    return ( $index + 0.5 ) * HEIGHT() / $DESCRIPTORS_COUNT;
}

sub Save {
    my $filename = $FILENAME;
    if (-e $filename) {
        say "File exists, perhaps you already saved this? \n ***NOT SAVING AGAIN***";
        return;
    }
    $CANVAS->postscript( -file => $filename, -pageheight => PAGEHEIGHT, -height => HEIGHT );
    # or confess "Failed to save $filename";
    say "Saved file $filename";
}

sub GenerateFilename {
    my $count = 1;
    while (-e "$DIR/$count.eps") {
        $count++;
    }
    $FILENAME = "$DIR/$count.eps";
}
