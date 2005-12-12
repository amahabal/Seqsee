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
use base qw{SReln};

 
# variable: %name_of
#    name of the slippage
my %name_of :ATTR( :get<name>);


# variable: %category_of
#    category slippage based on
my %category_of :ATTR( :get<category>);


# variable: %change_of_of
#    How is the info loss changing?
my %change_of_of :ATTR( :get<change_ref>);

# multi: find_reln ( SMetonymType, SMetonymType )
# finds relation between metonym types
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

multimethod find_reln => qw(SMetonymType SMetonymType) => sub {
    my ( $m1, $m2 ) = @_;
    my $cat1 = $m1->get_category;
    return unless $m2->get_category() eq $cat1;

    my $name1 = $m1->get_name;
    return unless $m2->get_name() eq $name1;

    # Now the meat: the info lost
    my $info_loss1 = $m1->get_info_loss;
    my $info_loss2 = $m2->get_info_loss;

    return unless scalar(keys %$info_loss1) == scalar(keys %$info_loss2);
    my $change_ref = {};
    while (my($k, $v) = each %$info_loss1) {
        return unless exists $info_loss2->{$k};
        my $v2 = $info_loss2->{$k};
        my $rel = find_reln($v, $v2);
        $change_ref->{$k} = $rel;
    }
    return SReln::MetoType->new({ category => $cat1,
                                  name => $name1,
                                  change => $change_ref,
                              });

};

sub BUILD{
    my ( $self, $id, $opts_ref ) = @_;
    $name_of{$id} = $opts_ref->{name} or confess "Need name";
    $category_of{$id} = $opts_ref->{category} or confess "Need Category";
    $change_of_of{$id} = $opts_ref->{change} or confess "Need change";
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
    while (my($k, $v) = each %$meto_info_loss) {
        if (not(exists $rel_change_ref->{$k})){
            $new_loss->{$k} = $v;
            next;
        }
        my $v2 = apply_reln( $rel_change_ref->{$k}, $v);
        $new_loss->{$k} = $v2;
    }
    return SMetonymType->new( {
        info_loss => $new_loss,
        name => $meto->get_name,
        category => $meto->get_category,
    });
    
};


1;


