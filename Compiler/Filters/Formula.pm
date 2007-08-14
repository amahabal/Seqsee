package Compiler::Filters::Formula;
use strict;
use File::Slurp qw{slurp};
use Parse::RecDescent;

use Class::Std;
use Smart::Comments;
use Compiler::Filter;

my %arglist_of :ATTR(:get<arglist>);
my %body_of :ATTR(:get<body>);

our %LIST;

sub BUILD{
    my ( $package, $id, $opts_ref ) = @_;
    $arglist_of{$id} = $opts_ref->{arglist};
    $body_of{$id} = $opts_ref->{body};
}


sub GenerateInsertText{
    my ( $self, $opts_ref ) = @_;
    my $id = ident $self;

    ## Generating: $opts_ref
    ## arglist: $arglist_of{$id}

    my $body = $body_of{$id};
    my %replacement;
    for my $arg (@{$arglist_of{$id}}) {
        ## arg: $arg
        my ($var, $sigil) = ($arg->{var}, $arg->{sigil});
        ## var, sigil: $var, $sigil
        if ($arg->{required}) {
            exists $opts_ref->{$var} or die "Required argument $var missing!";
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

Sigil: '$' { $return = '$'}


ArgList: Arg(s? /,/) {$return = $item[1]}

Arg: Sigil Identifier '!' { $return = { var => $item{Identifier}, sigil => $item{Sigil}, required => 1}}
    | Sigil Identifier '=' CodeBlock { $return = { var => $item{Identifier}, sigil => $item{Sigil}, 
                                             required => 0, default => $item{CodeBlock}}}

Formula_File: Formula(s?)

Formula: FullIdentifier '(' ArgList ')' OptionalReturns CodeBlock 
       { #print "@item", "\n";
         my ($name, $arglist, $body) = ($item{FullIdentifier}, $item{ArgList}, $item{CodeBlock});
         #print "NAB=$name~~$arglist~~>>$body<<\n";
         $Compiler::Filters::Formula::LIST{$name} = new Compiler::Filters::Formula({arglist => $arglist, body => $body});
        $return = 1;
 }
};

my $Grammar_For_Formula = q{
FormulaVar: Identifier '=>' PerlVar {$return = [ $item{Identifier}, $item{PerlVar}]}
OptionalFormulaVars: ',' FormulaVar(s? /,/) {$return = {map {@$_} @{$item[2]}}}| {$return = []}
Formula : "InsertFormula" "("  FullIdentifier OptionalFormulaVars ")" 
        # { print "Saw Formula $item[3]"}
        { $return = Compiler::Filters::Formula::ExpandFormula($item[3], $item[4])}
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
        $Filter = Compiler::Filter::CreateFilter("InsertFormula",
                                                 $Grammar_For_Formula,
                                                 "Formula"
                                                     );
        return $Filter;
    }
}
1;
