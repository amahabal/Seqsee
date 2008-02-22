package Transform::Structural;
use 5.10.0;
use strict;
use Carp;
use Smart::Comments;
use Memoize;

my %category_of :ATTR(:name<category>);
my %meto_mode_of :ATTR(:name<meto_mode>);
# ASSUMPTION: pos_mode_of is always forward.

my %position_reln_of :ATTR(:name<position_reln>);
my %metonymy_reln_of :ATTR(:name<metonymy_reln>);
my %direction_reln_of :ATTR(:name<direction_reln>);

my %changed_bindings_of_of :ATTR(:name<changed_bindings>);
my %slippages_of :ATTR(:name<slippages>);

sub create {
    my ( $package, $opts_ref ) = @_;
    my $meto_mode = $opts_ref->{meto_mode} or confess "need meto_mode";
    if (not $meto_mode->is_metonymy_present()) {
        $opts_ref->{metonymy_reln} = 'x';
    }
    if (not $meto_mode->is_position_relevant()) {
        $opts_ref->{position_reln} = 'x';
    }

    my $string = join('#',
                      (map { $opts_ref->{$_} }
                           qw(category meto_mode metonymy_reln position_reln)),
                      join(';', SUtil::hash_sorted_as_array(%{$opts_ref->{changed_bindings}})),
                      join(';', SUtil::hash_sorted_as_array(%{$opts_ref->{slippages}})),
                          );
    state %MEMO;
    return $MEMO{$string} ||= $package->new($opts_ref);
}

1;
