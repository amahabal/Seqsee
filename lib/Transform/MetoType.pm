package Transform::MetoType;
use 5.10.0;
use strict;
use Carp;
use Class::Std;
use Class::Multimethods;
use Smart::Comments;

my %category_of : ATTR( :name<category>);       # Category shared by both ends of relation.
my %name_of : ATTR( :name<name>);               # Shared name.
my %change_of_of : ATTR( :name<change_ref>);    # How the info lost is changing: key -> reln

sub create {
    my ( $package, $opts_ref ) = @_;
    my $string = join(';', $opts_ref->{category}, $opts_ref->{name}, %{ $opts_ref->{change_ref} } );
    state %MEMO;
    return $MEMO{$string} ||= $package->new($opts_ref);
}

multimethod FindTransform => qw(SMetonymType SMetonymType) => sub {
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
        my $rel = FindTransform( $v, $v2 ) or return;
        $change_ref->{$k} = $rel;
    }
    return Transform::MetoType->create(
        {   category => $cat1,
            name     => $name1,
            change_ref   => $change_ref,
        }
    );

};

multimethod ApplyTransform => qw(SReln::MetoType SMetonymType) => sub {
    my ( $rel, $meto ) = @_;
    my $meto_info_loss = $meto->get_info_loss;

    my $rel_change_ref = $rel->get_change_ref;

    my $new_loss = {};
    while ( my ( $k, $v ) = each %$meto_info_loss ) {
        if ( not( exists $rel_change_ref->{$k} ) ) {
            $new_loss->{$k} = $v;
            next;
        }
        my $v2 = ApplyTransform( $rel_change_ref->{$k}, $v );
        $new_loss->{$k} = $v2;
    }
    return SMetonymType->new(
        {   info_loss => $new_loss,
            name      => $meto->get_name,
            category  => $meto->get_category,
        }
    );

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
    my $id = ident $self;

    my $change = SUtil::StringifyForCarp($change_of_of{$id});
    my $category = SUtil::StringifyForCarp($category_of{$id});
    return "SReln::MetoType[$id](change=>$change, category=>$category)";
}

sub get_pure {
    return $_[0];
}

sub IsEffectivelyASamenessRelation {
    my ( $self ) = @_;
    my $id = ident $self;
    while (my($k, $v) = each %{$change_of_of{$id}}) {
        return unless $v->IsEffectivelyASamenessRelation;
    }
    return 1;
}
1;
