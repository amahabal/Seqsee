package Compile::SThought;
use base 'Compile::Seqsee';
use Module::Compile -base;

use Text::Balanced qw(extract_variable extract_codeblock);

use Class::Std;

my %package_name_of :ATTR;
my %required_params_of :ATTR;
my %optional_params_of :ATTR;
my %fringe_block_of :ATTR;
my %extended_fringe_block_of :ATTR;
my %build_block_of :ATTR;
my %actions_block_of :ATTR;
my %multis_of_of :ATTR;

my %generated_arg_pulling_of :ATTR;

sub handle_package{
    my ( $object, $block ) = @_;
    my $id = ident $object;
    if ($package_name_of{$id}) {
        die "A single code block had two package blocks!";
    }
    $block =~ s#^\s*##; $block =~ s#\s*$##;
    unless ($block =~ /^SThought::/) {
        die "package must start with SThought::";
    }
    $package_name_of{$id} = $block;
}

sub handle_build{
    my ( $object, $block ) = @_;
    my $id = ident $object;
    if ($build_block_of{$id}) {
        die "A single code block had two build blocks!";
    }
    $build_block_of{$id} = $block;
}

sub handle_param{
    my ( $object, $block ) = @_;
    my $id = ident $object;
    $block =~ s#^\s*##; $block =~ s#\s*$##;
    $block =~ m# ^ (\w+) (!?) $ #x or die "Cannot parse param $block";
    if ($2) {
        $required_params_of{$id}{$1} = 1;
    } else {
        $optional_params_of{$id}{$1} = 1;
    }
}

sub handle_params{
    my ( $object, $block ) = @_;
    my $id = ident $object;
    $block =~ s#^\s*##; $block =~ s#\s*$##;

    for (split(/\s*,\s*/, $block)) {
        $object->handle_param($_);
    }
}


sub handle_multi{
    my ( $object, $block ) = @_;
    my $id = ident $object;
    $block =~ s#^\s*##; $block =~ s#\s*$##;
    $multis_of_of{$id}{$block} = 1;
}

sub handle_fringe{
    my ( $object, $block ) = @_;
    my $id = ident $object;

    if ($fringe_block_of{$id}) {
        die "A single code block had two fringe blocks!";
    }

    $block = process_fringe($block);
    $fringe_block_of{$id} = $block;
}

sub handle_extended_fringe{
    my ( $object, $block ) = @_;
    my $id = ident $object;

    if ($extended_fringe_block_of{$id}) {
        die "A single code block had two extended_fringe blocks!";
    }

    $block = process_fringe($block);
    $extended_fringe_block_of{$id} = $block;
}

sub handle_actions{
    my ( $object, $block ) = @_;
    my $id = ident $object;

    if ($actions_block_of{$id}) {
        die "A single code block had two actions blocks!";
    }

    $block = process_codelet($block);
    $block = process_thoughts($block);
    $actions_block_of{$id} = $block;
}

sub process_fringe{
    my ( $str ) = @_;
    my $processed;
    while ($str =~ m# ((.|\n)*?) ^  \s* FRINGE \s*#xmgc) {
        $processed .= "$1\n";
        my ($activation, $fringe_element);
        {
            my ($act, $rest, $pre) = extract_int_or_variable($str);
            die "Failed to parse" unless defined $act;
            $activation = $act;
        }
        {
            $str =~ m#\s* , \s*#xmg or die "missing comma";
            ($fringe_element) = extract_variable($str);
            $fringe_element or die "missing fringe_element";
        }
        $str =~ m#\s* ;#mxg or die "Missing ;";
        $processed .= qq{push \@ret, [$fringe_element, $activation];} ."\n";
    }
    $processed .= substr($str, pos($str));
    return $processed;
}

sub process_codelet{
    my ( $str ) = @_;
    my $processed;
    while ($str =~ m# ((.|\n)*?) ^  \s* (CODELET|ACTION) \s*#xmgc) {
        my $specie = $3;
        $processed .= "$1\n";
        my ($urgency, $type, $option_hash);
        {
            my ($act, $rest, $pre) = extract_int_or_variable($str);
            die "Failed to parse" unless defined $act;
            $urgency = $act;
        }
        {
            $str =~ m#\s* , \s*#xmgc or die "missing comma";
            $str =~ m# (\S+) \s* , \s* #mxgc;
            $type = $1 or die "missing type";
        }
        {
            print "Looking at: ", substr($str, pos($str) -1, 10), "\n";
            ($option_hash) = extract_codeblock($str);
            die "Missing option_hash" unless $option_hash;
        }
        $str =~ m#\s* ;#mxgc or die "Missing ;";
        if ($specie eq "CODELET") {
            $processed .= <<"END";
        push \@ret, new SCodelet("$type", $urgency,
              $option_hash);

END
        } elsif ($specie eq "ACTION") {
            $processed .= <<"END";
        push \@ret, SAction->new( {
             family => "$type", 
             urgency => $urgency,
             args =>  $option_hash, });

END
        }
    }
    $processed .= substr($str, pos($str));
    return $processed;
}

sub process_thoughts{
    my ( $str ) = @_;
    my $processed;
    while ($str =~ m# ((.|\n)*?) ^  \s* THOUGHT \s*#xmgc) {
        $processed .= "$1\n";
        my ($type, $option_hash);
        {
            $str =~ m#\s* (\w+) \s* , \s*#xmgc or die "missing type";
            $type = $1 or _report_failed_parse($str, "missing type");
        }
        {
            print "Looking at: ", substr($str, pos($str) -1, 10), "\n";
            ($option_hash) = extract_codeblock($str);
            die "Missing option_hash" unless $option_hash;
        }
        $str =~ m#\s* ;#mxgc or die "Missing ;";
        $processed .= <<"END";
        push \@ret,
          SThought::${type}->new($option_hash);
END
    }
    $processed .= substr($str, pos($str));
    return $processed;
}


sub extract_int_or_variable{
    my ($matched, $rest, $prefix);
    if ($_[0] =~ m#\G (\s*) (\d+)#cgx) {
        return ($2, '', $1);
    } else {
        my ($matched, $rest, $prefix) = extract_variable($_[0]);
        return ($matched, $rest, $prefix);
    }
}

sub serialize{
    my ( $object ) = @_;
    my $id = ident $object;

    my $package = $package_name_of{$id};
    my $MULTIS = join "\n", map {
        "multimethod '$_';"
    } keys %{ $multis_of_of{$id} };

    my $VAR_DECLARATIONS = join("", map {
        "my \%${_}_of :ATTR(:get<$_>);\n"
    } (keys %{$required_params_of{$id}}, keys %{$optional_params_of{$id}}));

    my $build_arg_pulling = join("", map {
        "my \$$_ = \$${_}_of{\$id} = ".
            "\$opts_ref->{$_} or confess \"Missing required arg $_\";\n"
    } (keys %{$required_params_of{$id}}));
    $build_arg_pulling .= join("", map {
        "my \$$_ = \$${_}_of{\$id} = \$opts_ref->{$_} if exists(\$opts_ref->{$_});\n"
    } (keys %{$optional_params_of{$id}}));
    
    my $BUILD = <<"HERE";

sub BUILD{
    my ( \$self, \$id, \$opts_ref ) = \@_;
    $build_arg_pulling;
    $build_block_of{$id};
}

HERE

    $generated_arg_pulling_of{$id} = join("", map {
        "my \$$_ = \$${_}_of{\$id};\n"
    } (keys %{$required_params_of{$id}}, keys %{$optional_params_of{$id}}));

   my $FRINGE = <<"HERE";

sub get_fringe{
    my ( \$self ) = \@_;
    my \$id = ident \$self;
    $generated_arg_pulling_of{$id}
    my \@ret;
    $fringe_block_of{$id}
    return \\\@ret;
}

HERE

   my $EXTENDED_FRINGE = (!$extended_fringe_block_of{$id}) ? <<"DEFAULT" : <<"HERE";

sub get_extended_fringe{
    return [];
}


DEFAULT

sub get_extended_fringe{
    my ( \$self ) = \@_;
    my \$id = ident \$self; 
    $generated_arg_pulling_of{$id}
    my \@ret;
    $extended_fringe_block_of{$id}
    return \\\@ret;
}

HERE

   my $ACTIONS = (!$actions_block_of{$id}) ? <<"DEFAULT" : <<"HERE";

sub get_actions{
    return [];
}


DEFAULT

sub get_actions{
    my ( \$self ) = \@_;
    my \$id = ident \$self;
    $generated_arg_pulling_of{$id}
    my \@ret;
    $actions_block_of{$id}
    return \@ret;
}

HERE

my $UNCLAIMED = $object->get_unclaimed_lines();
$UNCLAIMED = process_fringe($UNCLAIMED);
$UNCLAIMED = process_thoughts($UNCLAIMED);
$UNCLAIMED = process_codelet($UNCLAIMED);

my $AS_TEXT = <<"HERE";

sub as_text{
    return "$package";
}


HERE

    my $serialized = <<"HERE";

{

package $package;
use strict;
use Carp;
use Smart::Comments;
use Log::Log4perl;
use English qw(-no_match_vars);
use Class::Multimethods;
use base qw{SThought};
use List::Util qw{min max};
use Class::Std;

$MULTIS
$VAR_DECLARATIONS
$UNCLAIMED
$BUILD
$FRINGE
$EXTENDED_FRINGE
$ACTIONS
$AS_TEXT

1;

} # end of package $package

HERE

    $serialized =~ s#\015\012#\012#g;
return $serialized;
}

sub _report_failed_parse{
    my $pos = pos($_[0]);
    my $error_str =  "$_[1]: I was looking at: " . 
        substr($_[0], $pos, 100) . "\n";
    my $earlier_context_size = (100 < $pos) ? 100 : $pos;
    $error_str .= "I had just processed: " . 
        substr($_[0],
               $pos - $earlier_context_size,
               $earlier_context_size ), "\n";
    die $error_str;
}


1;
