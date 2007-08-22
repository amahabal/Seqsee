package Compiler::Filters::CodeletFamily;
use strict;
use File::Slurp qw{slurp};
use Parse::RecDescent;

use Class::Std;
use Smart::Comments;
use Compiler::Filter;
use Carp;

my $Grammar_For_Family = q{
FAMILY: 'CodeletFamily' Identifier '(' ArgList ')' 'does' '{' NamedBlocksHash '}' 
       {
    $return = Compiler::Filters::CodeletFamily::GenerateFamilyCode( $item{Identifier},
        $item{ArgList}, $item{NamedBlocksHash} )
}

};

my %AllowedBlocks = map {$_ => 1 } qw(INITIAL RUN FINAL);
sub GenerateFamilyCode {
    my ( $package_name, $arguments, $blocks ) = @_;
    $package_name = "SCF::$package_name";
    print "GENERATE FAMILY CODE CALLED ON $package_name; blocks=$blocks\n";

    while (my($k, $v) = each %$blocks) {
        confess "UNKNOWN BLOCK $k!" unless $AllowedBlocks{$k};
    }

    my $INITIAL_BLOCK = $blocks->{INITIAL} || '';
    my $FINAL_BLOCK = $blocks->{FINAL} || '';
    my $RUN_BLOCK = $blocks->{RUN} || confess "No run block?";
    my $PARAMS = ArgumentsToString($arguments);

    my $serialized = <<"HERE";

{

package $package_name;
use strict;
use Carp;
use Smart::Comments;
use Log::Log4perl;
use English qw(-no_match_vars);
use SCF;

use Class::Multimethods;
$INITIAL_BLOCK

{
    my (\$logger, \$is_debug, \$is_info);
    BEGIN { \$logger   = Log::Log4perl->get_logger("$package_name"); 
           \$is_debug = \$logger->is_debug();
           \$is_info  = \$logger->is_info();
         }
    sub LOGGING_DEBUG() { \$is_debug; }
    sub LOGGING_INFO()  { \$is_info;  }
}

my \$logger = Log::Log4perl->get_logger("$package_name");

sub run{
    my ( \$action_object, \$opts_ref ) = \@_;
        if (LOGGING_INFO()) {
        my \$msg = \$action_object->generate_log_msg();

        \$logger->info( \$msg );
    }

    $PARAMS

    $RUN_BLOCK
}
 # end run
$FINAL_BLOCK

1;
} # end surrounding

HERE

print $serialized;
    return $serialized;
}

sub ArgumentsToString {
    my ( $arguments_array ) = @_;
    my $ret = '';

    for my $argument (@$arguments_array) {
        if ($argument->{required}) {
            my $name = $argument->{var};
            $ret .= qq{\tmy \$$name = \$opts_ref->{$name};\n};
            $ret .= qq{\tdefined(\$$name) \nor confess "Needed '$name', only got " . join(';', keys \%\$opts_ref);\n};
        } else {
            my $name = $argument->{var};
            my $default = $argument->{default};
            $ret .= qq{\tmy \$$name = \$opts_ref->{$name};\n};
            $ret .= qq{\t\$$name = $default unless defined(\$$name);\n};
        }
    }
    return $ret;
}


{
    my $Filter;
    sub GetFilter {
        return $Filter if $Filter;
        $Filter = Compiler::Filter::CreateFilter("CodeletFamily",
                                                 $Grammar_For_Family,
                                                 "FAMILY"
                                                     );
        unless ($Filter) {
            confess "Error creating filter Compiler::Filters::CodeletFamily";
        }
        return $Filter;
    }
}
1;
