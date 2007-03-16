package Compile::Style;
use base 'Compile::Seqsee';
use Module::Compile -base;
use Carp;

use Class::Std;
my %style_name_of : ATTR;
my %entries_of_of : ATTR;
my %params_of : ATTR;

sub handle_style {
    my ( $object, $block ) = @_;
    $style_name_of{ ident $object} = trim($block);
}

sub handle_params {
    my ( $object, $block ) = @_;
    $params_of{ ident $object} = trim($block);
}

sub trim {
    for ( $_[0] ) {
        s#^\s*##;
        s#\s*$##;
        return $_;
    }
}

sub DEFAULT_HANDLER {
    my ($self, $tag, $block) = @_;
    $entries_of_of{ident $self}{"-$tag"} = $block;
}


sub serialize{
    my ( $object ) = @_;
    my $id = ident($object);
    my $style = 'Style::' . $style_name_of{$id};
    my $params = $params_of{$id};
    my $param_list = $params ? "my ($params)= \@_;" : '';
    my $param_count = $params ? 1 + ($params =~ tr/,//) : 0;
    print "Param count: $param_count for $style\n";
    my $entries_ref = $entries_of_of{$id};
my $entries;
    while (my ($k,$v)=each %$entries_ref) {
        $entries.= "$k => do {$v},\n";
    }

    my $ret = <<"HERE";
{
sub $style {
confess "Incorrect number of arguments to $style!" unless scalar(\@_) == $param_count;
$param_list
my \%entries=($entries) ;
return \%entries;   
}
memoize('$style');
}

HERE
}


1;
