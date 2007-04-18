package Compile::SCF;
use base 'Compile::Seqsee';
use Module::Compile -base;

use Class::Std;

my %package_name_of :ATTR;
my %run_block_of :ATTR;
my %default_of_of :ATTR;
my %param_of_of :ATTR;


sub handle_package{
    my ( $object, $block ) = @_;
    my $id = ident $object;
    if ($package_name_of{$id}) {
        die "A single code block had two package blocks!";
    }
    $block =~ s#^\s*##; $block =~ s#\s*$##;
    unless ($block =~ /^SCF::/) {
        die "package must start with SCF::";
    }
    $package_name_of{$id} = $block;
}

sub handle_run{
    my ( $object, $block ) = @_;
    my $id = ident $object;
    if ($run_block_of{$id}) {
        die "A single code block had two run blocks!";
    }
    $run_block_of{$id} = $block;
}

sub handle_param{
    my ( $object, $block ) = @_;
    my $id = ident $object;
    $block =~ s#^\s*##; $block =~ s#\s*$##;
    if ($block =~ /=/) { # There is a default
        my ($name, $val, $rest ) = split(/=/, $block);
        die "Too many =s" if $rest;
        $name =~ s#^\s*##; $name =~ s#\s*$##;
        $default_of_of{$id}{$name} = $val;
    } else {
        $param_of_of{$id}{$block} = 1;
    }
}

sub handle_multi{
    my ( $object, $block ) = @_;
    my $id = ident $object;
    $block =~ s#^\s*##; $block =~ s#\s*$##;
    $multis_of_of{$id}{$block} = 1;
}

sub param_string{
    my ( $id ) = @_;
    my $ret;

    my $required_hash = $param_of_of{$id};
    for (keys %$required_hash) {
        my $is_necessary;
        if (m#!$#) { # Required!
            chop;
            $is_necessary = 1;
        }
        $ret .= "my \$$_ = \$opts_ref->{$_};\n";
        $ret .= "defined(\$$_) or confess \"Need '$_', only got '\" .join(';', keys \%\$opts_ref). \"'\";\n" if $is_necessary;
    }

    my $optional_hash = $default_of_of{$id};
    while (my($k, $v) = each %$optional_hash) {
        $ret .= "my \$$_ = \$opts_ref->{$_} || $v;\n";
    }

    return $ret;
}


sub serialize{
    my ( $object ) = @_;
    my $id = ident $object;

    my $package = $package_name_of{$id};
    my $MULTIS = join "\n", map {
        "multimethod '$_';"
    } keys %{ $multis_of_of{$id} };
    my $PARAMS = param_string($id);
    my $RUN_BLOCK = $run_block_of{$id};
    my $UNCLAIMED_LINES = $object->get_unclaimed_lines;

    my $serialized = <<"HERE";


{

package $package;
use strict;
use Carp;
use Smart::Comments;
use Log::Log4perl;
use English qw(-no_match_vars);
use SCF;

use Class::Multimethods;
$MULTIS

{
    my (\$logger, \$is_debug, \$is_info);
    BEGIN { \$logger   = Log::Log4perl->get_logger("$package"); 
           \$is_debug = \$logger->is_debug();
           \$is_info  = \$logger->is_info();
         }
    sub LOGGING_DEBUG() { \$is_debug; }
    sub LOGGING_INFO()  { \$is_info;  }
}

my \$logger = Log::Log4perl->get_logger("$package");

sub run{
    my ( \$action_object, \$opts_ref ) = \@_;
        if (LOGGING_INFO()) {
        my \$msg = \$action_object->generate_log_msg();

        \$logger->info( \$msg );
    }

    $PARAMS

    $RUN_BLOCK
}
 # end run
$UNCLAIMED_LINES

1;
} # end surrounding

HERE

return $serialized;

}




1;
