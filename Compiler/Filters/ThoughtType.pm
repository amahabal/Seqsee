package Compiler::Filters::ThoughtType;
use strict;
use File::Slurp qw{slurp};
use Parse::RecDescent;

use Class::Std;
use Smart::Comments;
use Compiler::Filter;
use Carp;

my $Grammar_For_ThoughtType = q{
THOUGHTTYPE: 'ThoughtType' Identifier '(' ArgList ')' 'does' '{' NamedBlocksHash '}' 
       {
    $return = Compiler::Filters::ThoughtType::GenerateThoughtCode( $item{Identifier},
        $item{ArgList}, $item{NamedBlocksHash} )
}

};

my %AllowedBlocks = map { $_ => 1 } qw(INITIAL FINAL FRINGE ACTIONS BUILD AS_TEXT NAME);

sub GenerateThoughtCode {
    my ( $package_name, $arguments, $blocks ) = @_;
    print "GENERATE THOUGHT CODE CALLED ON $package_name; blocks=$blocks\n";

    while ( my ( $k, $v ) = each %$blocks ) {
        confess "UNKNOWN BLOCK $k!" unless $AllowedBlocks{$k};
    }

    my $AS_TEXT_BLOCK = $blocks->{AS_TEXT} || "return '$package_name';";

    my $NAME = $blocks->{NAME} // $package_name;
    $NAME =~ s#^\s*##;
    $NAME =~ s#\s*$##;
    $NAME =~ s#\s+# #;

    $blocks->{BUILD} ||= '';

    my $VAR_DECLARATIONS        = ArgumentsToVarDeclarations($arguments);
    my $BUILD_ARGUMENT_PULLING  = ArgumentsToBuildPuller($arguments);
    my $OTHER_ARGUMENTS_PULLING = ArgumentsToOtherPuller($arguments);


    my $BUILD_BLOCK   = <<"BUILD_BLOCK";
    sub BUILD {
       my ( \$self, \$id, \$opts_ref ) = \@_;
       $BUILD_ARGUMENT_PULLING;
       $blocks->{BUILD};       
       }

BUILD_BLOCK

    my $FRINGE_BLOCK  = $blocks->{FRINGE}  || "";
    $FRINGE_BLOCK = filterFringe($FRINGE_BLOCK);
    $FRINGE_BLOCK = <<"FRINGE_BLOCK";
    sub get_fringe {
        my ( \$self ) = \@_;
        my \$id = ident \$self;
        $OTHER_ARGUMENTS_PULLING;
        my \@ret;
        $FRINGE_BLOCK;
        return \\\@ret;
    }

FRINGE_BLOCK
    
    my $ACTIONS_BLOCK = $blocks->{ACTIONS} || "";
    $ACTIONS_BLOCK = filterCodelet($ACTIONS_BLOCK);
    $ACTIONS_BLOCK = filterAction($ACTIONS_BLOCK);
    $ACTIONS_BLOCK = filterThought($ACTIONS_BLOCK);

    $ACTIONS_BLOCK = <<"ACTIONS_BLOCK";
    sub get_actions {
        my ( \$self ) = \@_;
        my \$id = ident \$self;
        $OTHER_ARGUMENTS_PULLING;
        our \@actions_ret = ();
        $ACTIONS_BLOCK;
        return \@actions_ret;
    }

ACTIONS_BLOCK

    my $INITIAL_BLOCK = $blocks->{INITIAL} || '';
    my $FINAL_BLOCK   = $blocks->{FINAL}   || '';

    for ($INITIAL_BLOCK, $FINAL_BLOCK) {
        $_ = filterFringe($_);
        $_ = filterAction($_);
        $_ = filterCodelet($_);
        $_ = filterThought($_);
    }

    my $serialized = <<"SERIALIZED";

    {
        package SThought::$package_name;
        use strict;
        use Carp;
        use Smart::Comments;
        use English qw(-no_match_vars);
        use Class::Multimethods;
        use base qw{SThought};
        use List::Util qw{min max};
        use Class::Std;

        our \@actions_ret;
our \$NAME = '$NAME';

        $VAR_DECLARATIONS;
        $INITIAL_BLOCK;
        $BUILD_BLOCK;
        $FRINGE_BLOCK;
        $ACTIONS_BLOCK;
        $FINAL_BLOCK;

        sub as_text {
            my \$self = shift;
            $AS_TEXT_BLOCK
        }

    }

SERIALIZED

return Compiler::Filter::tidy($serialized);
}

sub ArgumentsToVarDeclarations {
    my ( $arguments ) = @_;
    my $ret;
    for my $argument (@$arguments) {
        my $var = $argument->{var};
        $ret .= qq{\tmy \%${var}_of :ATTR(:get<$var>);\n};
    }
    return $ret;
}

sub ArgumentsToBuildPuller {
    my ( $arguments ) = @_;
    my $ret;
    for my $argument (@$arguments) {
        my $var = $argument->{var};
        my $required = $argument->{required};
        if ($required) {
            $ret .= qq{\tmy \$$var = \$${var}_of{\$id} = };
            $ret .= qq{\$opts_ref->{$var} or confess "Missing required argument $var";\n};
        } else {
            $ret .= qq{\tmy \$$var = \$${var}_of{\$id} = };
            $ret .= qq{(\$opts_ref->{$var} || $argument->{default});\n};
        }
    }
    return $ret;
}

sub ArgumentsToOtherPuller {
    my ( $arguments ) = @_;
    my $ret;
    for my $argument (@$arguments) {
        my $var = $argument->{var};
        $ret .= qq{\tmy \$$var = \$${var}_of{\$id};\n};
    }
    $ret;
}


{
    my $FringeFilterGrammar = q{
       Fringe: 'FRINGE' IntOrVar ',' PerlVar 
      {
          $return = qq{push \@ret, [$item{PerlVar}, $item{IntOrVar}];\n};
      }
    };
    my $FringeFilter = Compiler::Filter::CreateFilter( 'FRINGE', $FringeFilterGrammar, 'Fringe' );
    unless ($FringeFilter) {
        confess "Filter creation failed!";
    }
    sub filterFringe {
        my ($string) = @_;
        return $FringeFilter->($string);
    }
}

{
    my $CodeletFilterGrammar = q{
       Codelet: 'CODELET' IntOrVar ',' Identifier ',' CodeBlock 
      {
            $return = qq{push \@actions_ret, SCodelet->new("$item{Identifier}", 
                                                           $item{IntOrVar},
                                                           {$item{CodeBlock}}); \n};
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
            $return = qq{push \@actions_ret, SAction->new({ family => "$item{Identifier}", 
                                                            urgency => $item{IntOrVar},
                                                            args =>  {$item{CodeBlock}} }); \n};
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
           { $return = "push \@actions_ret, 
                        SThought::$item{Identifier}->new({$item{CodeBlock}});\n";
           }
    };
    my $ThoughtFilter
        = Compiler::Filter::CreateFilter( 'THOUGHT', $ThoughtFilterGrammar, 'Thought' );

    sub filterThought {
        my ($string) = @_;
        return $ThoughtFilter->($string);
    }
}

{
    my $Filter;
    sub GetFilter {
        return $Filter if $Filter;
        $Filter = Compiler::Filter::CreateFilter("ThoughtType",
                                                 $Grammar_For_ThoughtType,
                                                 "THOUGHTTYPE"
                                                     );
        unless ($Filter) {
            confess "Error creating filter Compiler::Filters::ThoughtType";
        }
        return $Filter;
    }
}

1;
