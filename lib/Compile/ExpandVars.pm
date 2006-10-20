package Compile::ExpandVars;
use Module::Compile -base;
use Carp;
use Smart::Comments;

sub pmc_compile {
    my ( $class, $src ) = @_;
    my %Vars;
    my $compiled;
    while ( $src =~ m#\G (.*?) \< \@ :#xsgc ) {
        $compiled .= change_vars( $1, \%Vars );
        ### compiled: $compiled
        $src =~ m#\G (\S+) \s+#xsgc or confess "Missing name";
        my $var_name = $1;
        ### var_name: $var_name
        $src =~ m#\G (.*?) : \@ > ; #xsgc or confess "No closing :@> found for $var_name";
        $Vars{$var_name} = change_vars( $1, \%Vars );
    }
    $compiled .= change_vars( substr( $src, pos($src) ), \%Vars );
    return $compiled;
}

sub change_vars {
    my ( $str, $var_hash_ref ) = @_;
    my $ret;
    while ( $str =~ m#\G (.*?) \< @ ([^:].*?) @>#xsgc ) {
        $ret .= $1;
        confess "Unknown variable $2" unless exists $var_hash_ref->{$2};
        $ret .= $var_hash_ref->{$2};
    }
    $ret .= substr( $str, pos($str) );
    return $ret;
}

1;
