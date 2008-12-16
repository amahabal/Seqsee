package Compiler::Filters::SeqseeDisplay;
use strict;
use Smart::Comments;
use Carp;
use Compiler::Filter;

my $Grammar = q{
SeqseeDisplay: 'SeqseeDisplay' Identifier 'is' '{' NamedBlocksHash '}'

    { $return
        = Compiler::Filters::SeqseeDisplay::GenerateCode( $item{Identifier},
        $item{NamedBlocksHash} ) }

};

sub GenerateCode {
    my ( $widget_name, $blocks_hash ) = @_;

    my $ConfigNames = $blocks_hash->{ConfigNames};
    trim($ConfigNames);
    my @ConfigNames = split(/\s+/, $ConfigNames);

    my $VarNames = $blocks_hash->{Variables};
    trim($VarNames);
    my @VarNames = split(/\s+/, $VarNames);
    my $VarNamesString = join(', ', map { '$'.$_ } (@VarNames, @ConfigNames) );

    my $PackageName = "SGUI::$widget_name";
    my $Preamble    = GeneratePreamble();
    my $InitialCode = $blocks_hash->{InitialCode} || '';
    my $BeginBlock = GenerateBeginBlock($widget_name.'Layout', \@ConfigNames);
    my $SetupBlock = GenerateSetupBlock($blocks_hash->{Setup});
    my $DrawItBlock = GenerateDrawItBlock($blocks_hash->{DrawIt});
    my $ExtraStuff  = $blocks_hash->{ExtraStuff};
    my $return = Compiler::Filter::tidy(qq{{
package $PackageName;
$Preamble
my ($VarNamesString);
$InitialCode
$BeginBlock $SetupBlock $DrawItBlock $ExtraStuff
    }
1;
});
}

sub GeneratePreamble {
    return qq{
use strict;
use Carp;
use Class::Std;
use Config::Std;
use base qw{};
use List::Util qw(min max);
use Sort::Key qw(rikeysort);

my \$Canvas;
my ( \$Height,  \$Width );
my ( \$XOffset, \$YOffset );

my \$Margin;
my \$EffectiveHeight;
my \$EffectiveWidth;

};
}

sub GenerateBeginBlock {
    my ( $config_set_name, $config_names ) = @_;
    my $var_list = join(", ", map { '$'.$_} @$config_names);
    my $names_list = join(' ', @$config_names);
    return qq{
    BEGIN {
        read_config 'config/GUI_ws3.conf' => my \%config;
        \$Margin = \$config{Layout}{Margin};

        my \%layout_options = \%{ \$config{$config_set_name} };
        ($var_list) = \@layout_options{ qw{$names_list} };
    }
    };
}

sub GenerateSetupBlock {
    my ( $setup ) = @_;
    return qq{
sub Setup {
    my \$package = shift;
    ( \$Canvas, \$XOffset, \$YOffset, \$Width, \$Height ) = \@_;
    \$EffectiveHeight = \$Height - 2 * \$Margin;
    \$EffectiveWidth  = \$Width - 2 * \$Margin;
    $setup;
}
 };
}

sub GenerateDrawItBlock {
    my ( $block ) = @_;
    return qq{sub DrawIt {my \$self = shift; $block} };
}


{
    my $Filter;

    sub GetFilter {
        return $Filter if $Filter;
        $Filter = Compiler::Filter::CreateFilter( "SeqseeDisplay", $Grammar, "SeqseeDisplay" );
        unless ($Filter) {
            confess "Error creating filter Compiler::Filters::SeqseeDisplay";
        }
        return $Filter;
    }
}

sub trim {
    for (@_) {
        s#^\s*##; s#\s*$##;
    }
}


1;
