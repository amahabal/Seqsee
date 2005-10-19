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
use base qw{};

 
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



1;


