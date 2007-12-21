package Compiler::Filter;
use strict;

our $Grammar = q{
# Identifier and FullIdentifier are valid perl names
Identifier: / [A-Za-z_] [A-Za-z0-9_]* /ix { $return = $item[1]}
FullIdentifier: Identifier(s /::/) { $return = join('::', @{$item[1]})}

PerlVar: <perl_variable> {$return = $item[1]}
IntOrVar: /\d+/ { $return = $item[1]}
   | PerlVar { $return = $item[1]}
NumOrVar: Num { $return = $item[1]}
   | PerlVar { $return = $item[1]}
Num: /\d+(\.\d+)?/ { $return = $item[1]}
OptionalSpace: /\s*/

Sigil: '$' { $return = '$'}

ArgList: Arg(s? /,/) {$return = $item[1]}

Arg: Sigil Identifier '!' 
          {
    $return = {
        var      => $item{Identifier},
        sigil    => $item{Sigil},
        required => 1
        }
}

| Sigil Identifier '=' CodeBlock 
          {
    $return = {
        var      => $item{Identifier},
        sigil    => $item{Sigil},
        required => 0,
        default  => $item{CodeBlock}
        }
}

NamedBlocksHash: NamedBlock(s) {
    $return = { map {@$_} @{ $item[1] } }
}

NamedBlocksArr: NamedBlock(s) {
    $return = $item[1]
}

NamedBlock: FullIdentifier ':' CodeBlock {
    $return = [ $item{FullIdentifier}, $item{CodeBlock} ]
}




CodeBlock: <perl_codeblock {}> 
           { my $ret = $item[1];

             # Get rid of curlies!
             $ret =~ s#^\s*\{##;
             chop($ret);
             $return = $ret; }
CodeBlockUnstripped: <perl_codeblock {}> { $return = $item[1]}
ProcessAnything: /.*?(?=$arg[0])/s <commit> (<matchrule: $arg[1]>|<error: Saw a $arg[0], but did not then see a $arg[1]! I was looking at $text>) { $return = [1,join('', $item[1], $item[3], $text)]}
                |{$return = [0, $text]}
};

sub _ReplaceAnything{
    my ( $string, $replace_rule, $parser) = @_;
    my ( $string ) = @_;
    my ($success, $new_string) = (1, $string);
    while ($success) {
        no strict 'subs';
        ($success, $new_string) = @{$parser->$replace_rule($new_string)};
        ## succ: $success, $new_string
    }
    ## tree: $tree
    return $new_string;
}

sub CreateFilter{
    my ( $keyword, $grammar_fragment, $top_rule ) = @_;
    my $new_grammar = join("\n", $Grammar,
                           $grammar_fragment,
                           "ThisFilter: ProcessAnything['$keyword', '$top_rule'] ",
                           "{\$return = \$item[1]}\n",
                               );
    my $parser = new Parse::RecDescent($new_grammar);
    return sub {
        my ( $string ) = @_;
        _ReplaceAnything($string, 'ThisFilter', $parser);
    };
}

use Perl::Tidy;
sub tidy {
    my ( $string ) = @_;
    my $ret;
    perltidy(source => \$string, destination => \$ret);
    return $ret;
}


1;
