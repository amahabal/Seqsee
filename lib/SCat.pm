package SCat;
use strict;
use Carp;
use Class::Std;
use Smart::Comments;

my %Recreation_String_of : ATTR;

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    my $str = $Recreation_String_of{$id} = $opts_ref->{to_recreate}
        or confess "Missing string to recreate";
    confess "Recreation_String may not contain newlines" if $str =~ m#\n#;
}

sub get_pure { return $_[0] }

# XXX(Board-it-up): [2006/11/06] Needs fixing: can have dependencies.
sub get_memory_dependencies { return; }

sub serialize {
    my ($self) = @_;
    return $Recreation_String_of{ ident $self};
}

sub deserialize {
    my ( $package, $string ) = @_;

    # print qq{Will resuscicate '$string'};
    return eval($string);    # Could be optimized, look out!
}

1;
