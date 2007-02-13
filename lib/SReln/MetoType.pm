#####################################################
#
#    Package: SReln::MetoType
#
#####################################################
#   Relationship between metonym types
#####################################################

package SReln::MetoType;
use strict;
use Carp;
use Class::Std;
use Class::Multimethods;
use Smart::Comments;
use base qw{SReln};

my %category_of : ATTR( :get<category>);       # Category shared by both ends of relation.
my %name_of : ATTR( :get<name>);               # Shared name.
my %change_of_of : ATTR( :get<change_ref>);    # How the info lost is changing: key -> reln

# multi: find_reln ( SMetonymType, SMetonymType )
multimethod find_reln => qw(SMetonymType SMetonymType) => sub {
    my ( $m1, $m2 ) = @_;
    my $cat1 = $m1->get_category;
    return unless $m2->get_category() eq $cat1;

    my $name1 = $m1->get_name;
    return unless $m2->get_name() eq $name1;

    # Now the meat: the info lost
    my $info_loss1 = $m1->get_info_loss;
    my $info_loss2 = $m2->get_info_loss;

    return unless scalar( keys %$info_loss1 ) == scalar( keys %$info_loss2 );
    my $change_ref = {};
    while ( my ( $k, $v ) = each %$info_loss1 ) {
        return unless exists $info_loss2->{$k};
        my $v2 = $info_loss2->{$k};
        my $rel = find_reln( $v, $v2 ) or return;
        $change_ref->{$k} = $rel->get_type();
    }
    return SReln::MetoType->create(
        {   category => $cat1,
            name     => $name1,
            change   => $change_ref,
        }
    );

};

{
    my %MEMO;

    sub create {
        my ( $package, $opts_ref ) = @_;
        my $string
            = join( ';', $opts_ref->{category}, $opts_ref->{name}, %{ $opts_ref->{change} } );
        ## Attempting Reln Metotype creation: $string
        return $MEMO{$string} ||= $package->new($opts_ref);
    }

}

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    $name_of{$id}      = $opts_ref->{name}     or confess "Need name";
    $category_of{$id}  = $opts_ref->{category} or confess "Need Category";
    $change_of_of{$id} = $opts_ref->{change}   or confess "Need change";
}

# multi: apply_reln ( SReln::MetoType, SMetonymType )
# apply metoreln to meto
#
#
#    usage:
#
#
#    parameter list:
#
#    return value:
#
#
#    possible exceptions:

multimethod apply_reln => qw(SReln::MetoType SMetonymType) => sub {
    my ( $rel, $meto ) = @_;
    my $meto_info_loss = $meto->get_info_loss;

    my $rel_change_ref = $rel->get_change_ref;

    my $new_loss = {};
    while ( my ( $k, $v ) = each %$meto_info_loss ) {
        if ( not( exists $rel_change_ref->{$k} ) ) {
            $new_loss->{$k} = $v;
            next;
        }
        my $v2 = apply_reln( $rel_change_ref->{$k}, $v );
        $new_loss->{$k} = $v2;
    }
    return SMetonymType->new(
        {   info_loss => $new_loss,
            name      => $meto->get_name,
            category  => $meto->get_category,
        }
    );

};

# XXX(Board-it-up): [2006/10/14] I am not at all sure this is the right thing to do, but seems
# easiest for now.
multimethod are_relns_compatible => qw(SReln::MetoType SReln::MetoType) => sub {
    my ( $r1, $r2 ) = @_;
    my ( $id1, $id2 ) = ( ident($r1), ident($r2) );
    return unless $name_of{$id1}     eq $name_of{$id2};
    return unless $category_of{$id1} eq $category_of{$id2};
    my %c1 = %{ $change_of_of{$id1} };
    my %c2 = %{ $change_of_of{$id2} };
    while ( my ( $k, $v ) = each %c1 ) {
        return unless are_relns_compatible( $v, $c2{$k} );
    }
    return 1;
};

sub get_memory_dependencies {
    my ($self) = @_;
    my $id = ident $self;
    return grep { ref($_) } ($category_of{$id}, values %{ $change_of_of{$id} });
}

sub serialize{
    my ( $self ) = @_;
    my $id = ident $self;

    return SLTM::encode($category_of{$id}, $name_of{$id}, $change_of_of{$id});
}

sub deserialize{
    my ( $package, $str ) = @_;
    my %opts;
    @opts{qw(category name change)} = SLTM::decode($str);
    return $package->create(\%opts);
}

sub as_text{
    my ( $self ) = @_;
    return 'SReln::MetoType ' . $self;
}





1;

