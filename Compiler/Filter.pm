package Compiler::Filter;
use strict;
#use Class::Std;

#my $filter_of :ATTR(:get<filter>);

#sub BUILD{
#    my ( $package, $id, $opts_ref ) = @_;
#    
#}


our $Grammar = q{
# Identifier and FullIdentifier are valid perl names
Identifier: / [A-Za-z_] [A-Za-z0-9_]* /ix { $return = $item[1]}
FullIdentifier: Identifier(s /::/) { $return = join('::', @{$item[1]})}

PerlVar: <perl_variable> {$return = $item[1]}
OptionalSpace: /\s*/
CodeBlock: <perl_codeblock {}> 
           { my $ret = $item[1];

             # Get rid of curlies!
             $ret =~ s#^\s*\{##;
             chop($ret);
             $return = $ret; }

ProcessAnything: /.*?(?=$arg[0])/s <matchrule: $arg[1]> { $return = [1,join('', $item[1], $item[2], $text)]}
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

1;
