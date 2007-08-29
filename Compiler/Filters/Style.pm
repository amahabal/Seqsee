package Compiler::Filters::Style;
use strict;
use Smart::Comments;
use Carp;
use Compiler::Filter;

my $Grammar_For_Style = q{
Style: 'STYLE' Identifier '(' ArgList ')' 'is' '{' NamedBlocksHash '}'
{
 $return = Compiler::Filters::Style::GenerateCode($item{Identifier}, $item{ArgList}, $item{NamedBlocksHash});
}
};

sub GenerateCode {
    my ( $style_name, $arguments, $blocks ) = @_;
    my $arguments_string = GetArgumentsString($arguments);
    my $sub_body         = GetSubBody($blocks);
    return Compiler::Filter::tidy(
        qq{ 
{
    sub Style::${style_name}{ $arguments_string; $sub_body }; memoize('Style::$style_name');
}
}
    );
}

sub GetSubBody {
    my ($blocks) = @_;
    my $ret;
    while ( my ( $k, $v ) = each %$blocks ) {
        $ret .= qq{-$k => do {$v},\n};
    }
    return qq{return ($ret);\n};
}

sub GetArgumentsString {
    my ($arguments) = @_;
    my @ret;
    for my $argument (@$arguments) {
        my $var      = $argument->{var};
        my $required = $argument->{required};
        if ($required) {
            push @ret, '$' . $var;
        }
        else {
            confess "For a style, all arguments are required! $var is missing a '!'";
        }
    }
    if (@ret) {
        my $count = scalar(@ret);
        my $params = join( ', ', @ret );
        return
            qq{scalar(\@_)==$count or confess "Needed exactly $count arguments!";\nmy ($params)=\@_;\n};
    }
    else {
        return qq{scalar(\@_)==0 or confess "Expected no arguments!";\n};
    }
}

{
    my $Filter;

    sub GetFilter {
        return $Filter if $Filter;
        $Filter = Compiler::Filter::CreateFilter( "STYLE", $Grammar_For_Style, "Style" );
        unless ($Filter) {
            confess "Error creating filter Compiler::Filters::Style";
        }
        return $Filter;
    }

}

1;
