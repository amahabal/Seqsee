package Compile::Scripts;
use base 'Compile::Seqsee';
use Module::Compile -base;
use Smart::Comments;
use Text::Balanced qw(extract_variable extract_codeblock);

use Class::Std;

my %package_name_of :ATTR;
my %default_of_of :ATTR;
my %param_of_of :ATTR;
my %steps_of_of :ATTR;

sub handle_script {
    my ( $object, $block ) = @_;
    $block =~ s#^\s*##; $block =~ s#\s*$##;
    my $id = ident $object;
    $package_name_of{$id} = $block;
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

sub handle_steps{
    my ( $object, $block ) = @_;
    my $id = ident $object;
    $block =~ s#^\s*##; $block =~ s#\s*$##;
    my @steps = split(/\*{5,}/, $block);
    ## block: $block
    for (@steps) {
        ## step: $_
    }
    $steps_of_of{$id} = \@steps;
    ## old_steps: \@steps
}


sub param_string{
    my ( $id ) = @_;
    my $ret = q{
my ( $stack, $step_, $args_ref );
if ( exists $opts_ref->{stack} ) {
    ( $stack, $step_, $args_ref ) =
      ( $opts_ref->{stack}, $opts_ref->{step}, $opts_ref->{args} );
}
else {
    ( $stack, $step_, $args_ref ) = ( [], 1, $opts_ref );
}
 } . "\n";

    my $required_hash = $param_of_of{$id};
    for (keys %$required_hash) {
        my $is_necessary;
        if (m#!$#) { # Required!
            chop;
            $is_necessary = 1;
        }
        $ret .= "my \$$_ = \$args_ref->{$_};\n";
        $ret .= "defined(\$$_) or confess \"In script \$package_name_: Need '$_', only got '\" .join(';', keys \%\$args_ref). \"'\";\n" if $is_necessary;
    }

    my $optional_hash = $default_of_of{$id};
    while (my($k, $v) = each %$optional_hash) {
        $ret .= "my \$$_ = \$args_ref->{$_} || $v;\n";
    }

    return $ret;
}


sub handle_multi{
    my ( $object, $block ) = @_;
    my $id = ident $object;
    $block =~ s#^\s*##; $block =~ s#\s*$##;
    $multis_of_of{$id}{$block} = 1;
}

sub script_block{
    my ( $id ) = @_;
    my $steps_ref = $steps_of_of{$id};
    ## steps_ref: $steps_ref
    my $ret;
    my $counter = 0;
    for (@{$steps_ref}, 'RETURN;') {
        $counter++;
        ## preexp: $_
        my $bulk = expand($_);
        ## postexp: $bulk
        $ret .= <<"HERE";

        if (\$step_ == $counter) {
           $bulk;
           \$step_++;
}

HERE

    }

    return $ret;
}

{

my $RETURN_replacement = q{
{my @new_stack = @$stack;
 return unless @new_stack;
my $top_frame = pop(@new_stack);
my ($step_no, $args, $name) = @$top_frame;
SCodelet->new($name, 10000, { step => $step_no,
                              args => $args,
                              stack => \@new_stack,
                            })->schedule();
return;
}
};

sub expand{
    my ( $block ) = @_;
    while ($block =~ s#RETURN\s*;#$RETURN_replacement#) {}

    my $processed;
    while ($block =~ m# ((.|\n)*?) ^ \s* SCRIPT \s* (\w+) \s* , #xmgc) {
        $processed .= "$1\n";
        my $scriptname_to_call = $3;
        my $options_hash = extract_codeblock($block);
        $block =~ m#\s* ;#mxgc or die "Missing ;";
        $processed .= <<"END";
        {
my \$new_stack = [\@\$stack, [\$step_+1, \$args_ref, \$package_name_]];
SCodelet->new('$scriptname_to_call', 10000, { step => 1,
                                            args => $options_hash,
                                            stack => \$new_stack
                                          })->schedule();
return;
}

END
    }
    $processed .= substr($block, pos($block));
    return $processed;
}
}

sub serialize{
    my ( $object ) = @_;
    my $id = ident $object;

    my $package = 'SCF::' . $package_name_of{$id};
    my $MULTIS = join "\n", map {
        "multimethod '$_';"
    } keys %{ $multis_of_of{$id} };
    my $PARAMS = param_string($id);
    my $SCRIPT_BLOCK = script_block($id);
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
        our \$package_name_ = '$package_name_of{$id}';
        $MULTIS
        sub run{
            my ( \$action_object, \$opts_ref ) = \@_;
            $PARAMS
            $SCRIPT_BLOCK
        }
        $UNCLAIMED_LINES
        1;

    }

HERE
return $serialized;
}

1;

