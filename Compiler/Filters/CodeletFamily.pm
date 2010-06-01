package Compiler::Filters::CodeletFamily;
use strict;
use File::Slurp qw{slurp};
use Parse::RecDescent;

use Class::Std;
use Smart::Comments;
use Compiler::Filter;
use Carp;

my $Grammar_For_Family = q{
IsScripted: 'scripted' { $return = 1}
OptionalScripted: IsScripted(?) 
    {
    if ( @{ $item[1] } ) { $return = 1; }
    else {
        $return = 0;
    }
}

FAMILY: 'CodeletFamily' Identifier '(' ArgList ')' 'does' OptionalScripted '{' NamedBlocksArr '}' 
    {
        if ( $item{OptionalScripted} ) {
            $return = Compiler::Filters::CodeletFamily::GenerateScriptCode( $item{Identifier},
                $item{ArgList}, $item{NamedBlocksArr} );
        }
        else {

            $return = Compiler::Filters::CodeletFamily::GenerateFamilyCode( $item{Identifier},
                $item{ArgList}, { map {@$_} @{$item{NamedBlocksArr}} } );
        }
    }

};


my $COMMON_PREAMBLE = q{
        use 5.10.0;
        use strict;
        use Carp;
        use Smart::Comments;
        use English qw(-no_match_vars);
        use SCF;
        
        use Class::Multimethods;
        multimethod 'FindMapping';
        multimethod 'ApplyMapping';
};

my %ScriptAllowedBlocks = map {$_ => 1 } qw(INITIAL FINAL STEP NAME);
sub GenerateScriptCode {
    my ( $package_name, $arguments, $blocks_list ) = @_;

    my %block_hash = map { @$_ } @$blocks_list; # Only one STEP survives in hash...
    while (my($k, $v) = each %block_hash) {
        confess "UNKNOWN BLOCK >>$k<<!" unless $ScriptAllowedBlocks{$k};
    }

    my @STEPS;
    for my $block (@$blocks_list) {
        my ($name, $content) = @$block;
        # print "SAW $name!\n";
        push @STEPS, $content if $name eq 'STEP';
    }

    my $INITIAL_BLOCK = $block_hash{INITIAL} || '';
    my $FINAL_BLOCK = $block_hash{FINAL} || '';
    my $PARAMS = ArgumentsToStringForScript($arguments);
    my $RUN_BLOCK = GenerateScriptRunBlock(@STEPS);
    my $NAME = $block_hash{NAME} // $package_name;
    $NAME =~ s#^\s*##;
    $NAME =~ s#\s*$##;
    $NAME =~ s#\s+# #;

    for ($INITIAL_BLOCK, $FINAL_BLOCK, $RUN_BLOCK) {
        $_ = filterCodelet($_);
        $_ = filterAction($_);
        $_ = filterThought($_);
    }

    my $serialized = <<"HERE";

{

package SCF::$package_name;
our \$package_name_ = '$package_name';
our \$NAME = '$NAME';
$COMMON_PREAMBLE
$INITIAL_BLOCK

sub run{
    my ( \$action_object, \$args_ref ) = \@_;
    $PARAMS
    $RUN_BLOCK
}
 # end run
$FINAL_BLOCK

1;
} # end surrounding

HERE
    return Compiler::Filter::tidy($serialized);
}

my %AllowedBlocks = map {$_ => 1 } qw(INITIAL NAME RUN FINAL);
sub GenerateFamilyCode {
    my ( $package_name, $arguments, $blocks ) = @_;
    $package_name = "SCF::$package_name";
    # print "GENERATE FAMILY CODE CALLED ON $package_name; blocks=$blocks\n";

    while (my($k, $v) = each %$blocks) {
        confess "UNKNOWN BLOCK >>$k<<!" unless $AllowedBlocks{$k};
    }

    my $INITIAL_BLOCK = $blocks->{INITIAL} || '';
    my $FINAL_BLOCK = $blocks->{FINAL} || '';
    my $RUN_BLOCK = $blocks->{RUN} || confess "No run block?";
    my $NAME = $blocks->{NAME} // $package_name;
    $NAME =~ s#^\s*##;
    $NAME =~ s#\s*$##;
    $NAME =~ s#\s+# #;
    
    for ($INITIAL_BLOCK, $FINAL_BLOCK, $RUN_BLOCK) {
        $_ = filterCodelet($_);
        $_ = filterAction($_);
        $_ = filterThought($_);
    }

    my $PARAMS = ArgumentsToString($arguments);

    my $serialized = <<"HERE";

{

package $package_name;
our \$package_name_ = '$package_name';
our \$NAME = '$NAME';
$COMMON_PREAMBLE
$INITIAL_BLOCK

sub run{
    my ( \$action_object, \$opts_ref ) = \@_;
    $PARAMS
    $RUN_BLOCK
}
 # end run
$FINAL_BLOCK

1;
} # end surrounding

HERE

#print $serialized;
    return Compiler::Filter::tidy($serialized);
}

sub ArgumentsToString {
    my ( $arguments_array ) = @_;
    my $ret = '';

    for my $argument (@$arguments_array) {
        if ($argument->{required}) {
            my $name = $argument->{var};
            $ret .= qq{\tmy \$$name = \$opts_ref->{$name} // confess "Needed '$name', only got " . join(';', keys \%\$opts_ref);\n};
        } else {
            my $name = $argument->{var};
            my $default = $argument->{default};
            $ret .= qq{\tmy \$$name = \$opts_ref->{$name} // $default;\n};
        }
    }
    return $ret;
}

sub ArgumentsToStringForScript {
    my ( $arguments_array ) = @_;
    my $preamble = q{
    my ( $stack, $step_, $opts_ref );
    if ( exists $args_ref->{__S_T_A_C_K__} ) {
        # print "args_ref->{__S_T_A_C_K__} present ($package_name_)\n";
        ( $stack, $step_, $opts_ref )
            = ( $args_ref->{__S_T_A_C_K__}, $args_ref->{__S_T_E_P__}, $args_ref->{__A_R_G_S__} );
    }
    else {
        # print "args_ref->{__S_T_A_C_K__} missing ($package_name_)\n";
        ( $stack, $step_, $opts_ref ) = ( [], 1, $args_ref );
    }
     };
    return $preamble . ArgumentsToString($arguments_array);
}


{
    my $Filter;
    sub GetFilter {
        return $Filter if $Filter;
        $Filter = Compiler::Filter::CreateFilter('\bCodeletFamily',
                                                 $Grammar_For_Family,
                                                 "FAMILY"
                                                     );
        unless ($Filter) {
            confess "Error creating filter Compiler::Filters::CodeletFamily";
        }
        return $Filter;
    }
}

sub GenerateScriptRunBlock {
    my ( @steps ) = @_;
    my $ret;
    my $counter = 0;
    for my $step_content (@steps, 'RETURN;') {
        $counter++;
        my $step_body = ExpandStepBody($step_content);
        $ret .= qq{ if ( \$step_ == $counter ) { $step_body; \$step_++;}};
    }
    return $ret;
}

sub ExpandStepBody {
    my ( $step_content ) = @_;
    $step_content = filterReturn($step_content);
    $step_content = filterScript($step_content);
    return $step_content;
}

{
    my $ScriptFilterGrammar = q(
      Script: "SCRIPT" Identifier ',' CodeBlockUnstripped {
        $return = qq{
           {
             my \$new_stack = [ \@\$stack, [\$step_ + 1, \$opts_ref, \$package_name_ ]];
             SCodelet->new('$item{Identifier}', 10000, {
                  __S_T_E_P__ => 1,
                  __A_R_G_S__ => $item{CodeBlockUnstripped},
                  __S_T_A_C_K__ => \$new_stack})->schedule();
             return;
            }
        };
      }
    );
    my $ScriptFilter
        = Compiler::Filter::CreateFilter( 'SCRIPT', $ScriptFilterGrammar, 'Script' );

    sub filterScript {
        my ($string) = @_;
        return $ScriptFilter->($string);
    }    
}

{
    my $ReturnFilterGrammar = q(
      Return: 'RETURN' ';'
           { $return = q{
 {
    my @new_stack = @$stack;
    return unless @new_stack;
    my $top_frame = pop(@new_stack);
    my ( $step_no, $args, $name ) = @$top_frame;
    SCodelet->new(
        $name, 10000,
        {   __S_T_E_P__   => $step_no,
            __A_R_G_S__   => $args,
            __S_T_A_C_K__ => \@new_stack,
        }
    )->schedule();
    return;
}}});
    my $ReturnFilter
        = Compiler::Filter::CreateFilter( 'RETURN', $ReturnFilterGrammar, 'Return' );

    sub filterReturn {
        my ($string) = @_;
        return $ReturnFilter->($string);
    }
}

{
    my $CodeletFilterGrammar = q{
       Codelet: 'CODELET' IntOrVar ',' Identifier ',' CodeBlock 
      {
            $return = qq{SCodelet->new("$item{Identifier}", 
                         $item{IntOrVar},
                         {$item{CodeBlock}})->schedule(); \n};
      }
    };
    my $CodeletFilter
        = Compiler::Filter::CreateFilter( 'CODELET', $CodeletFilterGrammar, 'Codelet' );

    sub filterCodelet {
        my ($string) = @_;
        return $CodeletFilter->($string);
    }
}

{
    my $ActionFilterGrammar = q{
       Action: 'ACTION' IntOrVar ',' Identifier ',' CodeBlock 
      {
            $return = qq{SAction->new({ family => "$item{Identifier}", 
                                        urgency => $item{IntOrVar},
                                        arguments =>  {$item{CodeBlock}} })->conditionally_run(); \n};
      }
    };
    my $ActionFilter = Compiler::Filter::CreateFilter( 'ACTION', $ActionFilterGrammar, 'Action' );

    sub filterAction {
        my ($string) = @_;
        return $ActionFilter->($string);
    }
}

{
    my $ThoughtFilterGrammar = q{
      Thought: 'THOUGHT' Identifier ',' CodeBlock
           { $return = "ContinueWith(SThought::$item{Identifier}->new({$item{CodeBlock}}));\n";
           }
    };
    my $ThoughtFilter
        = Compiler::Filter::CreateFilter( 'THOUGHT', $ThoughtFilterGrammar, 'Thought' );

    sub filterThought {
        my ($string) = @_;
        return $ThoughtFilter->($string);
    }
}


1;
