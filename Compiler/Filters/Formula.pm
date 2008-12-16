package Compiler::Filters::Formula;
use strict;
use File::Slurp qw{slurp};
use Parse::RecDescent;

use Class::Std;
use Smart::Comments;
use Compiler::Filter;
use Carp;

my %arglist_of :ATTR(:name<arglist>);
my %body_of :ATTR(:name<body>);
my %name_of :ATTR(:name<name>);

our %LIST;

sub GenerateInsertText{
    my ( $self, $opts_ref ) = @_;
    my $id = ident $self;

    ## Generating: $opts_ref
    ## arglist: $arglist_of{$id}

    my $body = $body_of{$id};
    my $name = $name_of{$id};
    my %replacement;
    for my $arg (@{$arglist_of{$id}}) {
        ## arg: $arg
        my ($var, $sigil) = ($arg->{var}, $arg->{sigil});
        ## var, sigil: $var, $sigil
        if ($arg->{required}) {
            exists $opts_ref->{$var} 
                or die "Cannot proceed with expanding formula $name: required argument $var missing!";
            $replacement{$sigil.$var} = $opts_ref->{$var};
        } else {
            if (exists $opts_ref->{$var}) {
                $replacement{$sigil.$var} = $opts_ref->{$var};
            } else {
                $replacement{$sigil.$var} = $arg->{default};
            }
        }
    }

    ## body: $body
    $body =~ s#(\$[a-zA-Z_][a-zA-Z0-9_]*)#exists($replacement{$1})?$replacement{$1}:$1#ge;
    #while ()
    ## body after loop: $body
    #    <STDIN>;
    # }
    return $body;
}

my $FormulaFileGrammarFragment = q{
OptionalReturns: 'returns' Identifier { $return = 1} | { $return = 1}


Formula_File: Formula(s?)

Formula: FullIdentifier '(' ArgList ')' OptionalReturns CodeBlock 
    {    #print "@item", "\n";
        my ( $name, $arglist, $body ) = ( $item{FullIdentifier}, $item{ArgList}, $item{CodeBlock} );

        #print "NAB=$name~~$arglist~~>>$body<<\n";
        $Compiler::Filters::Formula::LIST{$name}
            = new Compiler::Filters::Formula( { name => $name, arglist => $arglist, body => $body } );
           print "Noted new formula for >>$name<<\n";
        $return = 1;
    }
     | FullIdentifier '=>' '{' NameValuePairs '}' ';' {
        my $top = $item{FullIdentifier};
        for my $pair (@{$item{NameValuePairs}}) {
           my ($k, $v) = @$pair;
           my $name = $top . '::' . $k;
           $Compiler::Filters::Formula::LIST{$name} = new Compiler::Filters::Formula({ name => $name,
                    arglist => [], body => $v
                  });
           print "Noted new formula for >>$name<<\n";
        }
        $return = 1;
     }

NameValuePairs: NameValuePair(s /,/) Comma(?) { $return = $item[1]}
NameValuePair: FullIdentifier '=>' BlockOrNumOrVar { $return = [$item[1], $item[3]]}
BlockOrNumOrVar: NumOrVar { $return = $item[1]} | CodeBlock { $return = $item[1]} 
Comma: ',' 
};

my $Grammar_For_Formula = q{
FormulaVar: Identifier '=>' PerlVar {$return = [ $item{Identifier}, $item{PerlVar}]}
OptionalFormulaVars: ':' FormulaVar(s? /,/) {$return = {map {@$_} @{$item[2]}}}| {$return = []}
IdentifierNameParts: FullIdentifier(s /,/) { $return = join('::', @{$item[1]})}
Formula : "««"  IdentifierNameParts  OptionalFormulaVars "»»" 
        # { print "Saw Formula $item[3]"}
        { $return = Compiler::Filters::Formula::ExpandFormula($item[2], $item[3])}
};

$::RD_HINT = 1;
my $JointGrammar = join("\n", $Compiler::Filter::Grammar, 
                        $FormulaFileGrammarFragment);
## JointGrammar: $JointGrammar
my $FormulaFileParser = Parse::RecDescent->new($JointGrammar);

sub ReadFormulaFile{
    my ( $package, $filename ) = @_;
    my $file_content = slurp($filename);
    $FormulaFileParser->Formula_File($file_content);
}

sub ExpandFormula{
    my ( $formula_name, $opts_ref ) = @_;
    ### Expanding formula: $formula_name, $opts_ref
    my $formula = $LIST{$formula_name};
    return $formula->GenerateInsertText($opts_ref);
}

{
    my $Filter;
    sub GetFilter {
        return $Filter if $Filter;
        $Filter = Compiler::Filter::CreateFilter("««",
                                                 $Grammar_For_Formula,
                                                 "Formula"
                                                     );
       unless ($Filter) {
            confess "Error creating filter Compiler::Filters::Formula";
        }
        return $Filter;
    }
}
1;
