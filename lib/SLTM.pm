package SLTM;
use strict;
use warnings;
use Class::Multimethods;
use File::Slurp;
use Carp;
use Smart::Comments;

use SLTM::Platonic;

use constant {
    LTM_FOLLOWS        => 1,    # Link of type A often follows B in sequences
    LTM_IS             => 2,    # A is an instance of B
    LTM_CAN_BE_SEEN_AS => 3,    # A has been squinted as B
    LTM_TYPE_COUNT     => 3,    #
};

our @PRECALCULATED = @SActivation::PRECALCULATED;
confess "Load order issues" unless @PRECALCULATED;

our %MEMORY;                    # Just has the index into @MEMORY.
our @MEMORY;                    # Is 1-based, so that I can say $MEMORY{$x} || ...
our @ACTIVATIONS;               # Also 1-based, an array of SActivation objects.
our @LINKS;                     # List of all links, for decay purposes.
our @OUT_LINKS;                 # Also 1-based; Outgoing links from given node.
our $NodeCount;                 # Number of nodes.
our %_PURE_CLASSES_;            # List of pure classes: those that can be stored in the LTM.
our %CurrentlyInstalling;       # We are currently installing these. Needed to detect cycles.

%_PURE_CLASSES_ = map { $_ => 1 } qw(SCat::OfObj SLTM::Platonic SRelnType::Simple
    SRelnType::Compound METO_MODE POS_MODE SReln::Position SReln::MetoType SReln::Dir);

Clear();

# method Clear( $package:  )
sub Clear {
    %MEMORY      = ();
    $NodeCount   = 0;
    @MEMORY      = ('!!!');                       # Remember, its 1-based
    @ACTIVATIONS = ( SNodeActivation->new() );    # Remember, this, too, is 1-based
    @LINKS       = ();
    @OUT_LINKS   = ('!!!');
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
    push @ACTIVATIONS, SNodeActivation->new();
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

    if ( my $link = $outgoing_links_ref->{$to_index} ) {
        return $link;
    }
    else {
        my $new_link = SLinkActivation->new($modifier_index);
        $outgoing_links_ref->{$to_index} = $new_link;
        push @LINKS, $new_link;
        return $new_link;
    }
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
    my $root_name = $MEMORY[$root_index]->as_text();
    my %nodes_at_distance_below_1 = ( $root_index, 0 );    # Keys are nodes.
          # values are amount of activation pumped into them.

    my $activation = $ACTIVATIONS[$root_index][$SNodeActivation::REAL_ACTIVATION];   # is fn faster?
    for my $link_set ( @{ $OUT_LINKS[$root_index] } ) {
        while ( my ( $target_index, $link ) = each %$link_set ) {
            my $amount_to_spread = $link->AmountToSpread($activation);
            $ACTIVATIONS[$target_index]->Spike( int($amount_to_spread) );
            $nodes_at_distance_below_1{$target_index} += $amount_to_spread;
            my $node_name = $MEMORY[$target_index]->as_text();
            main::debug_message(
                "distance = 1 [$target_index] >$node_name< got an extra $amount_to_spread from >$root_name<",
                1, 1
            );
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
                my $node_name = $MEMORY[$target_index]->as_text();
                main::debug_message(
                    "distance = 2 [$target_index] >$node_name< got an extra $amount_to_spread from >$root_name<",
                    1, 1
                );
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
        my ($depth_reciprocal) = ( $activation->[SNodeActivation::DEPTH_RECIPROCAL], );
        print {$filehandle} "=== $index: ", ref($pure), " $depth_reciprocal\n", $pure->serialize(),
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
                print {$filehandle} sprintf( "%4s %4s %2s %4s %7.4f %7.5f\n",
                    $from_node, $to_node, $type, $modifier_index, $significance, $stability );
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
    ## links: $links

    my @nodes = split( qr{=== \d+:}, $nodes );
    for (@nodes) {
        s#^\s*##;
        s#\s*$##;
        next if m#^$#;
        my ( $type_and_sig, $val ) = split( /\n/, $_, 2 );
        my ( $type, $depth_reciprocal ) = split( /\s/, $type_and_sig, 2 );
        ## type, val: $type, $val
        my $pure = $type->deserialize($val);
        ## pure: $pure
        confess qq{Could not find pure: type='$type', val='$val'} unless defined($pure);
        my $index = InsertNode($pure);
        SetDepthReciprocalForIndex( $index, $depth_reciprocal );
    }
    ## nodes: @nodes

    my @links = split( /\n+/, $links );
    ## links split: @links
    for (@links) {
        s#^\s*##;
        s#\s*$##;
        next if m#^$#;
        my ( $from, $to, $type, $modifier_index, $significance, $stability ) = split( /\s+/, $_ );
        my $activation = __InsertLinkUnlessPresent( $from, $to, $modifier_index, $type );
        $activation->[ SActivation::RAW_SIGNIFICANCE() ]     = $significance;
        $activation->[ SActivation::STABILITY_RECIPROCAL() ] = $stability;
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

    # The / 5 in next line: too many concepts end up hyperactive o/w. This limits their
    # influence at load time, yet biases a little bit towards faster activation.
    # Also, now stability rises only if *for several problems* significance is high.
    $activation_object->[SActivation::RAW_SIGNIFICANCE]     = int( $significance / 5 );
    $activation_object->[SActivation::STABILITY_RECIPROCAL] = $stability;
}

sub SetDepthReciprocalForIndex {
    my ( $index, $depth_reciprocal ) = @_;
    $ACTIVATIONS[$index][SNodeActivation::DEPTH_RECIPROCAL] = $depth_reciprocal;
}

sub SetRawActivationForIndex {
    my ( $index, $activation ) = @_;
    $ACTIVATIONS[$index]->[SActivation::RAW_ACTIVATION] = $activation;
}

sub SpikeBy {
    my ( $amount, $concept ) = @_;
    ## Mem index: GetMemoryIndex($concept)
    ## @ACTIVATIONS: @ACTIVATIONS
    SNodeActivation::SpikeSeveral( $amount, $ACTIVATIONS[ GetMemoryIndex($concept) ] );
}

my $DecayString = qq{
    sub {
        SNodeActivation::DecayManyTimes(1, \@ACTIVATIONS);
        for ( \@LINKS ) {
            $SActivation::DECAY_CODE;
        }
    }
};

*DecayAll = eval $DecayString;

sub GetRawActivationsForIndices {
    my ($index_ref) = @_;
    return [ map { $ACTIVATIONS[$_]->[SNodeActivation::RAW_ACTIVATION] } @$index_ref ];
}

sub GetRealActivationsForIndices {
    my ($index_ref) = @_;
    return [ map { $ACTIVATIONS[$_]->[SNodeActivation::REAL_ACTIVATION] } @$index_ref ];
}

sub GetRealActivationsForConcepts {
    my ($index_ref) = @_;
    return [ map { $ACTIVATIONS[ GetMemoryIndex($_) ]->[SNodeActivation::REAL_ACTIVATION] }
            @$index_ref ];
}

sub GetRealActivationsForOneConcept {
    my ($concept) = @_;
    return $ACTIVATIONS[ GetMemoryIndex( $_[0] ) ]->[SNodeActivation::REAL_ACTIVATION];
}

{
    my $chooser_given_indices = SChoose->create(
        { map => q{$SLTM::ACTIVATIONS[$_]->[SNodeActivation::REAL_ACTIVATION]} } );
    my $chooser_given_concepts = SChoose->create(
        { map => q{$SLTM::ACTIVATIONS[$SLTM::MEMORY{$_}]->[SNodeActivation::REAL_ACTIVATION]} } );

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
            $ACTIVATIONS[$_]->[SNodeActivation::REAL_ACTIVATION],
            $ACTIVATIONS[$_]->[SNodeActivation::RAW_ACTIVATION],
        ]
    } ( 1 .. $NodeCount );
}

sub FindActiveFollowers {
    my ( $node, $cutoff ) = @_;
    $cutoff ||= 0.3;

    my $node_id = GetMemoryIndex($node);
    my $follows_links_ref = ( $OUT_LINKS[$node_id][LTM_FOLLOWS] ||= {} );
    return @MEMORY[ grep { $ACTIVATIONS[$_][ SActivation::REAL_ACTIVATION() ] > $cutoff }
        keys %$follows_links_ref ];
}

1;
