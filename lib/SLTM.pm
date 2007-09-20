package SLTM;
use strict;
use warnings;
use Class::Multimethods;
use File::Slurp;
use Carp;
use Smart::Comments;

use SLTM::Platonic;
use SActivation;    # In order to use constnts defined there.

use constant {
    LTM_FOLLOWS        => 1,
    LTM_IS             => 2,
    LTM_CAN_BE_SEEN_AS => 3,
    LTM_TYPE_COUNT     => 3,
};

our @PRECALCULATED = @SActivation::PRECALCULATED;

our %MEMORY;                 # Just has the index into @MEMORY.
our @MEMORY;                 # Is 1-based, so that I can say $MEMORY{$x} || ...
our @ACTIVATIONS;            # Also 1-based, an array of SActivation objects.
our @OUT_LINKS;                  # Also 1-based; Outgoing links from given node.
our $NodeCount;              # Number of nodes.
our %_PURE_CLASSES_;         # List of pure classes: those that can be stored in the LTM.
our %CurrentlyInstalling;    # We are currently installing these. Needed to detect cycles.

%_PURE_CLASSES_ = map { $_ => 1 } qw(SCat::OfObj SLTM::Platonic SRelnType::Simple
    SRelnType::Compound METO_MODE POS_MODE SReln::Position SReln::MetoType SReln::Dir);

Clear();

# method Clear( $package:  )
sub Clear {
    %MEMORY      = ();
    $NodeCount   = 0;
    @MEMORY      = ('!!!');                   # Remember, its 1-based
    @ACTIVATIONS = ( SActivation->new() );    # Remember, this, too, is 1-based
    @OUT_LINKS       = ('!!!');
}

# method GetNodeCount( $package:  ) returns int
sub GetNodeCount { return $NodeCount; }

# Always call as: SLTM::GetMemoryIndex($x), not SLTM->GetMemoryIndex($x)
sub GetMemoryIndex {
    ### ensure: $_[0] ne "SLTM"
    ## GetMemoryIndex called on: $_[0]
    my $pure = $_[0]->get_pure();
    ## pure: $pure
    return $MEMORY{$pure} ||= InsertNode($pure);
}

*InsertUnlessPresent = *GetMemoryIndex;

sub InsertNode {
    ### ensure: $_[0] ne "SLTM"
    ### ensure: $_[0] and $_PURE_CLASSES_{ref($_[0])}
    my ($pure) = @_;

    ## Currently installing: %CurrentlyInstalling, $pure
    confess if $CurrentlyInstalling{$pure}++;
    for ( $pure->get_memory_dependencies() ) {
        $MEMORY{$_} or InsertNode($_);
    }

    $NodeCount++;
    push @MEMORY, $pure;
    ## ACTIVATIONS: @ACTIVATIONS
    push @ACTIVATIONS, SActivation->new();
    ## ACTIVATIONS NOW: @ACTIVATIONS
    push @OUT_LINKS, [];
    $MEMORY{$pure} = $NodeCount;

    ## Finished installing: $pure
    delete $CurrentlyInstalling{$pure};
    return $NodeCount;
}

sub __InsertLinkUnlessPresent {
    my ( $from_index, $to_index, $modifier_index, $type ) = @_;
    my $outgoing_links_ref = ( $OUT_LINKS[$from_index][$type] ||= {} );

    return ($outgoing_links_ref->{$to_index} ||= SLinkActivation->new($modifier_index));
}

sub InsertFollowsLink {
    @_ == 3 or confess "Need 3 arguments";
    my ( $from, $to, $relation ) = @_;
    __InsertLinkUnlessPresent( GetMemoryIndex($from), GetMemoryIndex($to),
        GetMemoryIndex($relation), LTM_FOLLOWS, );
}

sub InsertISALink {
    my ( $from, $to ) = @_;
    __InsertLinkUnlessPresent( GetMemoryIndex($from), GetMemoryIndex($to), 0, LTM_IS );
}

sub StrengthenLinkGivenIndex {
    my ( $from, $to, $type, $amount ) = @_;
    my $outgoing_links_ref = ( $OUT_LINKS[$from][$type] ||= {} );
    ### require: exists($outgoing_links_ref->{$to})
    $outgoing_links_ref->{$to}->Spike($amount);
}

sub StrengthenLinkGivenNodes {
    my ( $from, $to, $type, $amount ) = @_;
    StrengthenLinkGivenIndex( GetMemoryIndex($from), GetMemoryIndex($to) );
}

sub SpreadActivationFrom {
    my ($root_index) = @_;
    my %nodes_at_distance_below_1 = ( $root_index, 0 );    # Keys are nodes.
          # values are amount of activation pumped into them.

    my $activation = $ACTIVATIONS[$root_index][$SActivation::REAL_ACTIVATION];    # is fn faster?
    for my $link_set ( @{ $OUT_LINKS[$root_index] } ) {
        while ( my ( $target_index, $link ) = each %$link_set ) {
            my $amount_to_spread = $link->AmountToSpread($activation);
            $ACTIVATIONS[$target_index]->Spike( int($amount_to_spread) );
            $nodes_at_distance_below_1{$target_index} += $amount_to_spread;
        }
    }

    # Now to nodes at distance 2.
    while ( my ( $node, $amount_spiked_by ) = each %nodes_at_distance_below_1 ) {
        next unless $amount_spiked_by > 5;
        for my $link_set ( @{ $OUT_LINKS[$node] } ) {
            while ( my ( $target_index, $link ) = each %$link_set ) {
                next if exists $nodes_at_distance_below_1{$target_index};
                my $amount_to_spread = $link->AmountToSpread($activation);
                $amount_to_spread *= 0.3;
                $ACTIVATIONS[$target_index]->Spike( int($amount_to_spread) );
            }
        }
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

    for my $index ( 1 .. $NodeCount ) {
        my ( $pure, $activation ) = ( $MEMORY[$index], $ACTIVATIONS[$index] );
        my ( $significance, $stability ) = (
            $activation->[SActivation::RAW_SIGNIFICANCE],
            $activation->[SActivation::STABILITY_RECIPROCAL]
        );
        print {$filehandle} "=== $index: ", ref($pure), " $significance $stability\n", $pure->serialize(),
            "\n";
    }

    # Links.
    print {$filehandle} "#####\n";
    for my $from_node ( 1 .. $NodeCount ) {
        my $links_ref = $OUT_LINKS[$from_node];
        for my $type ( 1 .. LTM_TYPE_COUNT ) {
            my $links_of_this_type = $links_ref->[$type];
            while ( my ( $to_node, $link ) = each %$links_of_this_type ) {
                my $modifier_index = $link->[SActivation::MODIFIER_NODE_INDEX] || 0;
                my ( $significance, $stability ) = (
                    $link->[SActivation::RAW_SIGNIFICANCE],
                    $link->[SActivation::STABILITY_RECIPROCAL]
                );
                print {$filehandle} sprintf("%4s %4s %2s %4s %7.4f %7.5f\n", $from_node, $to_node, $type, $modifier_index, $significance, $stability);
            }
        }
    }

    close $filehandle;
}

# method Load( $package: Str $filename )
sub Load {
    my ( $package, $filename ) = @_;
    Clear();
    my $string = read_file($filename);
    my ( $nodes, $links ) = split( q{#####}, $string );
    ## nodes: $nodes
    ### links: $links

    my @nodes = split( qr{=== \d+:}, $nodes );
    for (@nodes) {
        s#^\s*##;
        s#\s*$##;
        next if m#^$#;
        my ( $type_and_sig, $val ) = split( /\n/, $_, 2 );
        my ( $type, $significance, $stability ) = split( /\s/, $type_and_sig, 3 );
        ## type, val: $type, $val
        my $pure = $type->deserialize($val);
        ## pure: $pure
        confess qq{Could not find pure: type='$type', val='$val'} unless defined($pure);
        my $index = InsertNode($pure);
        SetSignificanceAndStabilityForIndex( $index, $significance, $stability );
    }
    ## nodes: @nodes

    my @links = split( /\n+/, $links );
    ### links split: @links
    for (@links) {
        s#^\s*##;
        s#\s*$##;
        next if m#^$#;
        my ( $from, $to, $type, $modifier_index, $significance, $stability ) = split( /\s+/, $_ );
        my $activation = __InsertLinkUnlessPresent($from, $to, $modifier_index, $type);
        $activation->[SActivation::RAW_SIGNIFICANCE()] = $significance;
        $activation->[SActivation::STABILITY_RECIPROCAL()] = $stability;
    }

    ## links: $links

    # print "Would have loaded the file\n";
}

{
    my ( $sep1, $sep2, $char1, $char2 ) = map { chr($_) } ( 129 .. 132 );
    my $rx1 = qr{^$char1(.*)};
    my $rx2 = qr{^$char2(.*)};

    sub encode {
        return join(
            $sep1,
            map {
                my $class = ref($_);
                $class eq 'HASH' ? encode_hash($_)
                    : $class ? $char1 . $MEMORY{$_}
                    : $_
                } @_
        );
    }

    sub encode_hash {
        my ($hash_ref) = @_;
        return $char2 . join(
            $sep2,
            map {
                my $class = ref($_);
                $class eq 'HASH' ? confess('')
                    : $class ? $char1 . $MEMORY{$_}
                    : $_
                } %$hash_ref
        );
    }

    sub decode {
        my ($str) = @_;
        return map { $_ =~ $rx1 ? $MEMORY[$1] : $_ =~ $rx2 ? { decode_hash($1) } : $_ }
            split( $sep1, $str );
    }

    sub decode_hash {
        my ($str) = @_;
        ## decode_hash called on: $str
        $str =~ s#$sep2#$sep1#g;
        ## string now: $str
        return decode($str);
    }
}

sub SetSignificanceAndStabilityForIndex {
    my ( $index, $significance, $stability ) = @_;
    my $activation_object = $ACTIVATIONS[$index];
    $activation_object->[SActivation::RAW_SIGNIFICANCE]     = $significance;
    $activation_object->[SActivation::STABILITY_RECIPROCAL] = $stability;
}

sub SetRawActivationForIndex {
    my ( $index, $activation ) = @_;
    $ACTIVATIONS[$index]->[SActivation::RAW_ACTIVATION] = $activation;
}

sub SpikeBy {
    my ( $amount, $concept ) = @_;
    ## Mem index: GetMemoryIndex($concept)
    ## @ACTIVATIONS: @ACTIVATIONS
    $ACTIVATIONS[ GetMemoryIndex($concept) ]->Spike( int($amount) );
}

my $DecayString = qq{
    sub {
        for ( \@ACTIVATIONS ) {
            $SActivation::DECAY_CODE;
        }
    }
};

*DecayAll = eval $DecayString;

sub GetRawActivationsForIndices {
    my ($index_ref) = @_;
    return [ map { $ACTIVATIONS[$_]->[SActivation::RAW_ACTIVATION] } @$index_ref ];
}

sub GetRealActivationsForIndices {
    my ($index_ref) = @_;
    return [ map { $ACTIVATIONS[$_]->[SActivation::REAL_ACTIVATION] } @$index_ref ];
}

sub GetRealActivationsForConcepts {
    my ($index_ref) = @_;
    return [ map { $ACTIVATIONS[ GetMemoryIndex($_) ]->[SActivation::REAL_ACTIVATION] }
            @$index_ref ];
}

{
    my $chooser_given_indices
        = SChoose->create( { map => q{$SLTM::ACTIVATIONS[$_]->[SActivation::REAL_ACTIVATION]} } );
    my $chooser_given_concepts = SChoose->create(
        { map => q{$SLTM::ACTIVATIONS[$SLTM::MEMORY{$_}]->[SActivation::REAL_ACTIVATION]} } );

    sub ChooseIndexGivenIndex {
        return $chooser_given_indices->( $_[0] );
    }

    sub ChooseConceptGivenIndex {
        return $MEMORY[ $chooser_given_indices->( $_[0] ) ];
    }

    sub ChooseIndexGivenConcept {
        return $MEMORY{ $chooser_given_concepts->( $_[0] ) };
    }

    sub ChooseConceptGivenConcept {
        return $chooser_given_concepts->( $_[0] );
    }
}

# method GetRelated( $package: SNode $node ) returns @LTMNodes
# method WhoGotExcited( $package: LTMNode @nodes ) returns @LTMNodes

# proto method GetMemoryActions (...) returns @SAction
# multi method GetMemoryActions( SElement $e )
# multi method GetMemoryActions( SAnchored $o )
# multi method GetMemoryActions( SReln $r )

# XXX(Board-it-up): [2006/11/15] dummy function
sub GetTopConcepts {
    my ($N) = @_;
    return map {
        [   $MEMORY[$_],
            $ACTIVATIONS[$_]->[SActivation::REAL_ACTIVATION],
            $ACTIVATIONS[$_]->[SActivation::RAW_ACTIVATION],
            $ACTIVATIONS[$_]->[SActivation::RAW_SIGNIFICANCE]
        ]
    } ( 1 .. $NodeCount );
}

1;
