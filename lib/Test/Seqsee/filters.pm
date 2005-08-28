package Test::Seqsee::filters;

use Exporter;
use Carp;

use base qw{Exporter};
our @EXPORT = qw{run_commands
    construct_and_commands
};

use Test::Base;
use Test::Base::Filter -base;
use S;
use Text::Balanced qw{extract_variable};

sub Test::Base::Filter::Sfrom_string {
    my ( $self, @data ) = @_;
    my $dataline = shift(@data);
    my $Object   = SBuiltObj->new_from_string($dataline);
    $Object = _construction_command_processing( $Object, @data );
    return $Object;
}

sub Test::Base::Filter::Sconstruct {
    my ( $self, @data ) = @_;
    my $dataline = shift(@data);
    my $Object;
    if ( $dataline =~ /^\s*(\d+)\s*$/ ) {
        $Object = SInt->new( { mag => $1 } );
    }
    else {
        $Object = SBuiltObj->new_deep( @{ eval "($dataline)" } );
    }
    $Object = _construction_command_processing( $Object, @data );
    return $Object;
}

sub Test::Base::Filter::Sbuild {
    my ( $self, @data ) = @_;
    my $dataline = shift(@data);
    my ( $type, $args ) = split( /\s+/, $dataline, 2 );
    $args ||= "";    # to silence warnings
    $args = eval "{ $args }";
    no strict 'refs';
    my $cat = ${"S::$type"};
    UNIVERSAL::isa( $cat, "SCat" ) or confess "$type not a cat!";
    my $Object = $cat->build($args);
    $Object = _construction_command_processing( $Object, @data );
    return $Object;
}

sub _construction_command_processing {
    my $Object = shift;
    for my $dataline (@_) {

        # print "Will process: '$dataline'\n";
        my ( $first_part, $rest ) = split( /\s+/, $dataline, 2 );
        no strict 'refs';
        if ( $first_part =~ /^\s*!/ ) {
            $dataline =~ /^\s*!(.*)/;
            eval $1;
        }
        elsif ( $first_part eq "blemish" ) {
            my $blemish = ${"S::$rest"};
            UNIVERSAL::isa( $blemish, "SBlemishType" )
                or confess "'$rest' is not a blemish I know! ($blemish)";
            $Object = $blemish->blemish($Object);
        }
        elsif ( $first_part eq "blemish_at" ) {
            my ( $name, $pos ) = eval $rest;

            # print "name = $name, pos = $pos\n";
            my $blemish = ${"S::$name"};
            UNIVERSAL::isa( $blemish, "SBlemishType" )
                or confess "'$rest' is not a blemish I know! ($blemish)";
            $pos = SPos->new($pos) unless UNIVERSAL::isa( $pos, "SPos" );
            $Object = $Object->apply_blemish_at( $blemish, $pos );
        }
        elsif ( $first_part eq "is_instance" ) {
            my $cat = $rest;
            $cat = ${"S::$cat"};
            confess "need cat" unless UNIVERSAL::isa( $cat, "SCat" );
            $Object = $cat->is_instance($Object);
        }
        else {
            confess "Don't know how to '$dataline'\n";
        }
    }
    return $Object;
}

sub Test::Base::Filter::oddman {
    my ( $self, @built_object_strings ) = @_;

  # print "Oddman filter: data = '", join("'\n---\n'", @built_objects), "'\n";
    my $cat = main::process_oddman(@built_object_strings);
    if ($cat) {
        return $cat->get_name();
    }
    else {
        return "???";
    }
}

sub run_commands {
    my ( $object, $command_list ) = @_;
    my $ok_so_far = 1;
    for (@$command_list) {
        $_ =~ s/^\s*//;
        $_ =~ s/\s*$//;
        my $ok = run_command( $object, $_ );
        next if ($ok);
        $ok_so_far = 0;
        print STDERR "Failed '$_'\n";
    }
    return $ok_so_far;
}

sub run_command {
    my ( $object, $command ) = @_;
    my ( $first_part, $rest ) = split( /\s+/, $command, 2 );
    if ( $first_part eq "isa" ) {
        return UNIVERSAL::isa( $object, $rest );
    }
    if ( $first_part eq "is_undef" ) {
        return ( defined $object ) ? 0 : 1;
    }
    if ( $first_part eq "self" ) {
        return $object eq eval($rest);
    }
    if ( $command =~ /^\.(.*)/ ) {
        my $string = '$object->' . $1;

        #print "String: $string\n";
        my ( $first_part, $rest ) = extract_variable($string);
        $rest =~ s#^\s*,##;

        #print "First Part: $first_part\n";
        #print "Rest: $rest\n";
        my $value = eval $first_part;
        $rest = eval $rest;

        #print "First Part: $value => '", as_string($value), "'\n";
        #print "Rest: $rest => '", as_string($rest), "'\n";
        #<STDIN>;
        my $ret = my_comapre_deep( $value, $rest );
        unless ($ret) {
            diag "Expected \n";
            diag as_string($rest);
            diag "\n\nGot \n";
            diag as_string($value);
        }
        return $ret;
    }
    confess "Unknown MTL command '$command'";
    if ( $first_part =~ /^\.(.*)/ ) {

        # method call!
        my $method = $1;
        my $value  = $object->$method();
        my $rest   = eval $rest;

        # print "Got value = '$value', rest = '$rest'\n";
    }
}

sub as_string {
    my $structure = shift;
    if ( ref $structure ) {
        return "[ " . join( ", ", map { as_string($_) } @$structure ) . " ]";
    }
    else {
        return $structure;
    }
}

sub my_comapre_deep {
    my ( $a, $b ) = @_;
    if ( ref($a) =~ /ARRAY/ and ref($b) =~ /ARRAY/ ) {

        # print "Comparing @$a and @$b\n";
        return unless @$a == @$b;
        for ( my $i = 0; $i < @$a; $i++ ) {
            return unless my_comapre_deep( $a->[$i], $b->[$i] );
        }
        return 1;
    }
    elsif ( ref($a) =~ /HASH/ and ref($b) =~ /HASH/ ) {
        return unless ( keys %$a ) == keys(%$b);
        foreach my $key ( keys %$a ) {
            return unless my_comapre_deep( $a->{$key}, $b->{$key} );
        }
        return 1;
    }
    elsif ( !ref($a) and !ref($b) ) {
        return $a eq $b;
    }
    else {
        return;
    }
}

sub construct_and_commands {
    for my $block ( blocks() ) {
        my $constructed = $block->{construct}[0]
            || $block->{build}[0]
            || $block->{string_build}[0];

        #print $constructed, "\n";
        #$constructed->show;
        my $commands = $block->{mtl};
        ok( run_commands( $constructed, $commands ) );
    }
}

1;
