#####################################################
#
#    Package: SRelnType::Compound
#
#####################################################
#   Type of relation; Should contain enough info to uniquely identify, and also
#   to resuscicate from string.
#####################################################

package SRelnType::Compound;
use strict;
use Carp;
use Class::Std;
use base qw{};

my %string_representation_of : ATTR;
my %base_category_of : ATTR;
my %base_meto_mode_of : ATTR;
my %pos_mode_of : ATTR;
my %changed_bindings_of_of : ATTR;
my %metonymy_reln_of : ATTR;

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    $base_category_of{$id}         = $opts_ref->{base_cat};
    $base_meto_mode_of{$id}        = $opts_ref->{meto_mode};
    $pos_mode_of{$id}              = $opts_ref->{posn_mode};
    $changed_bindings_of_of{$id}   = $opts_ref->{changed};
    $metonymy_reln_of{$id}         = $opts_ref->{meto_reln};
    $string_representation_of{$id} = $opts_ref->{string};
}

{
    my %MEMO = ();

    sub create {
        my ( $package, $reln ) = @_;
        my $cat_id           = SLTM->GetExactId( $reln->get_base_category() );
        my $meto_mode_of     = SLTM->GetExactId( $reln->get_base_meto_mode() );
        my $pos_mode_of      = SLTM->GetExactId( $reln->get_base_pos_mode() );
        my $meto_reln        = SLTM->GetExactId( $reln->get_metonymy_reln() );
        my %changed_bindings = %{ $reln->get_changed_bindings_ref() };
        while ( my ( $k, $v ) = each %changed_bindings ) {
            $v = SLTM->GetExactId($v);
        }
        my $string = join( '#',
            $cat_id, $meto_mode_of, $pos_mode_of, $meto_reln,
            join( ";", map { "$_=>" . $changed_bindings{$_} } keys %changed_bindings ) );

        return $MEMO{$string} ||= $package->new(
            {   base_cat  => $reln->get_base_category(),
                meto_mode => $reln->get_base_meto_mode(),
                posn_mode => $reln->get_base_pos_mode(),
                meto_reln => $reln->get_metonymy_reln(),
                changed   => { %{ $reln->get_changed_bindings_ref() } },
                string    => $string,
            }
        );
    }

    sub resuscicate {
        my ( $package, $string ) = @_;

        # Assumption: all components already resuscicated.
        my ( $cat_id, $meto_mode_of, $pos_mode_of, $meto_reln, $change_string )
            = split( '#', $string );

        my $change = {};
        for ( split( ';', $change_string ) ) {
            my ( $k, $v ) = split( '=>', $_, 2 );
            $change->{$k} = GetObjectAtId($v);
        }

        return $MEMO{$string} = $package->new(
            {   base_cat  => GetObjectAtId($cat_id),
                meto_mode => GetObjectAtId($meto_mode_of),
                posn_mode => GetObjectAtId($pos_mode_of),
                meto_reln => GetObjectAtId($meto_reln),
                string    => $string,
                change    => $change,
            }
        );
    }
}

sub as_text {
    my ($self) = @_;
    return $string_representation_of{ ident $self};
}

sub as_dump {
    my ($self) = @_;
    return $string_representation_of{ ident $self};
}

1;
