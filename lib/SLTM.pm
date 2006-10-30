package SLTM;
use Class::Multimethods;
use File::Slurp;
use Carp;
use Smart::Comments;

use SLTM::Platonic;

our %MEMORY;    # Just has the index into @MEMORY.
our @MEMORY;    # Is 1-based, so that I can say $MEMORY{$x} || ...
our $NodeCount;

# method Clear( $package:  )
sub Clear {
    %MEMORY    = ();
    $NodeCount = 0;
    @MEMORY    = ('!!!');    # Remember, its 1-based
}

# method GetNodeCount( $package:  ) returns int
sub GetNodeCount {
    return $NodeCount;
}

# method InsertNode( $package: SNode $node ) returns SNode
sub InsertNode {
    my ( $package, $node ) = @_;
    $NodeCount++;
    $MEMORY{ $node->get_core() } = $NodeCount;
    return $MEMORY[$NodeCount] = $node;
}

# proto method GetExactFromMemory (...) returns SNode
# multi method GetExactFromMemory( SCat $cat )
# multi method GetExactFromMemory( SObject )
# multi method GetExactFromMemory( SReln $rel )

multimethod GetExactFromMemory => qw(SObject) => sub {
    my ($object) = @_;

    # Maps to the platonic node in memory corresponding to the same structure string
    my $core = SLTM::Platonic->create( $object->get_structure_string() );
    my $id   = $MEMORY{$core};
    return $id ? $MEMORY[$id] : SLTM->InsertNode( SNode->new( { core => $core } ) );
};

multimethod GetExactId => qw($ SObject) => sub {
    my ( $package, $object ) = @_;
    my $core = SLTM::Platonic->create( $object->get_structure_string() );
    my $id   = $MEMORY{$core};
    return $id if $id;
    GetExactFromMemory($object);
    return $MEMORY{$core};
};

multimethod GetExactFromMemory => qw(SReln::Simple) => sub {
    my ($reln) = @_;
    my $core   = SRelnType::Simple->create($reln);
    my $id     = $MEMORY{$core};
    return $id ? $MEMORY[$id] : SLTM->InsertNode( SNode->new( { core => $core } ) );
};

multimethod GetExactId => qw($ SReln::Simple) => sub {
    my ( $package, $reln ) = @_;
    my $core = SRelnType::Simple->create($reln);
    my $id   = $MEMORY{$core};
    return $id if $id;
    GetExactFromMemory($reln);
    return $MEMORY{$core};
};

multimethod GetExactFromMemory => qw(SReln::Compound) => sub {
    my ($reln) = @_;

    # Maps to the platonic relation in memory corresponding to the non end specific part.
    my $core = SRelnType::Compound->create($reln);
    my $id   = $MEMORY{$core};
    return $id ? $MEMORY[$id] : SLTM->InsertNode( SNode->new( { core => $core } ) );
};

multimethod GetExactId => qw($ SReln::Compound) => sub {
    my ( $package, $reln ) = @_;
    my $core = SRelnType::Compound->create($reln);
    my $id   = $MEMORY{$core};
    return $id if $id;
    GetExactFromMemory($reln);
    return $MEMORY{$cat};
};

{    # Cases where object is the core...
    my $exact_sub = sub {
        my ($object) = @_;

        # The index into memory would be itself; When loading from file, it will be ensured that
        # all objects map to the right place
        my $id = $MEMORY{$object};
        return $id ? $MEMORY[$id] : SLTM->InsertNode( SNode->new( { core => $object } ) );
    };

    my $exact_id_sub = sub {
        my ( $package, $object ) = @_;
        my $id = $MEMORY{$object};
        return $id if $id;
        GetExactFromMemory($object);
        return $MEMORY{$object};
    };

    for (qw(SCat METO_MODE POS_MODE)) {
        multimethod GetExactFromMemory => ($_) => $exact_sub;
        multimethod GetExactId => ( '$', $_ ) => $exact_id_sub;
    }
}

# method Dump( $package: Str $filename )
sub Dump {
    my ( $package, $file ) = @_;
    my $filehandle;

    if ( my $type = ref $file ) {
        if ( $type eq q{File::Temp} ) {
            $filehandle = $file;
        }
        else {
            confess "Dump must be called either with an unblessed filename or a File::Temp object";
        }
    }
    else {
        open $filehandle, ">", $file;
    }

    shift @MEMORY;    # Remember, its 1-based
    for (@MEMORY) {
        my $core = $_->get_core();

        # print "Will dump $core\n";
        print $filehandle "=== ", ref($core), "\n", $core->as_dump(), "\n";
    }

    close $filehandle;
}

# method Load( $package: Str $filename )
sub Load {
    my ( $package, $filename ) = @_;
    Clear();
    my $string = read_file($filename);
    my ( $nodes, $links ) = split( q{^^^^^}, $string );
    ## nodes: $nodes
    my @nodes = split( qr{===}, $nodes );
    for (@nodes) {
        s#^\s*##;
        s#\s*$##;
        next if m#^$#;
        my ( $type, $val ) = split( /\n/, $_, 2 );
        ## type, val: $type, $val
        my $core = $type->resuscicate($val);
        ## core: $core
        confess qq{Could not find core: type='$type', val='$val'} unless defined($core);
        SLTM->InsertNode( SNode->new( { core => $core } ) );
    }
    ## nodes: @nodes

    ## links: $links

    # print "Would have loaded the file\n";
}

# method GetRelated( $package: SNode $node ) returns @LTMNodes
# method WhoGotExcited( $package: LTMNode @nodes ) returns @LTMNodes

# proto method GetMemoryActions (...) returns @SAction
# multi method GetMemoryActions( SElement $e )
# multi method GetMemoryActions( SAnchored $o )
# multi method GetMemoryActions( SReln $r )

1;
