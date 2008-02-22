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

sub FlippedVersion {
    my ( $self ) = @_;
    my $id = ident $self;
    my $new_slippages = _FlipSlippages($slippages_of{$id}) or return;
    my $new_bindings_change = _FlipChangedBindings($changed_bindings_of_of{$id}) or return;
    my $new_position_reln = $position_reln_of{$id}->FlippedVersion() if ref($position_reln_of{$id});
    my $new_metonymy_reln = $metonymy_reln_of{$id}->FlippedVersion() if ref($metonymy_reln_of{$id});
    my $new_direction_reln = $direction_reln_of{$id}->FlippedVersion() if ref($direction_reln_of{$id});

    return Transform::Structural->create({
        category => $category_of{$id},
        meto_mode => $meto_mode_of{$id},
        position_reln => $new_position_reln,
        metonymy_reln => $new_metonymy_reln,
        direction_reln => $new_direction_reln,
        changed_bindings => $new_bindings_change,
        slippages => $new_slippages,
            });
}

sub _FlipChangedBindings {
    my ( $old_bindings ) = @_;
    my %new_bindings;
    while (my($k, $v) = each %$old_bindings) {
        my $new_v = $v->FlippedVersion() or return;
        $new_bindings{$k} = $new_v;
    }
    return \%new_bindings;
}

sub _FlipSlippages {
    my ( $old_slipages ) = @_;
    my %new_slippages;
    my %keys_seen;
    while (my($k, $v) = each %$old_slipages) {
        return if $keys_seen{$v};
        $new_slippages{$v} = $k;
    }
    return \%new_slippages;
}
1;
