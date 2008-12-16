package Compiler::Filters::TryCatch;
use strict;
use Smart::Comments;
use Carp;
use Compiler::Filter;

my $Grammar = q{
TryCatch: 'TRY' CodeBlock 'CATCH' '{' NamedBlocksArr '}'
     { $return = Compiler::Filters::TryCatch::GenerateCode($item{CodeBlock}, $item{NamedBlocksArr}) }
};

sub GenerateCode {
    my ( $try_block, $catch_block ) = @_;
    $catch_block = GenerateCatchBlock($catch_block);
    my $serialized = qq{
       eval { $try_block };
       if (my \$err = \$EVAL_ERROR) {
          CATCH_BLOCK: { $catch_block }
       }
    };
    return Compiler::Filter::tidy($serialized);
}

sub GenerateCatchBlock {
    my ( $catch_block_ref ) = @_;
    my $ret;
    for my $block (@$catch_block_ref) {
        my ($name, $code) = @$block;
        if ($name eq 'DEFAULT') {
            $ret .= qq{ $code; last CATCH_BLOCK; };
        } else {
            $ret .= qq{if (UNIVERSAL::isa(\$err, 'SErr::$name')) { $code; last CATCH_BLOCK; }};
        }
    }
    $ret .= qq{die \$err};
    return $ret;
}

{
    my $Filter;

    sub GetFilter {
        return $Filter if $Filter;
        $Filter = Compiler::Filter::CreateFilter( "TRY", $Grammar, "TryCatch" );
        unless ($Filter) {
            confess "Error creating filter Compiler::Filters::TryCatch";
        }
        return $Filter;
    }

}

1;


