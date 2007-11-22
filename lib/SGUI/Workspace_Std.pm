package SGUI::Workspace_Std;
use Smart::Comments;
use base 'SGUI::Workspace';
my $AttentionDistribution;

sub DrawLegend {

}

sub PrepareForDrawing {
    my ($self) = @_;
    $AttentionDistribution = SCoderack->AttentionDistribution();
    ## AttentionDistribution: $AttentionDistribution
}

sub find_element_style {
    my ( $display, $element ) = @_;
    my $attention = $AttentionDistribution->{$element} || 0;
    return Style::ElementAttention( $attention );
}

sub find_group_style {
    my ( $display, $group, $is_meto, $is_largest ) = @_;
    my $attention = $AttentionDistribution->{$group} || 0;
    return Style::GroupAttention( $attention );
}

sub find_relation_style {
    my ( $display, $reln, $is_hilit ) = @_;
    my $attention = $AttentionDistribution->{$reln} || 0;
    return Style::RelationAttention( $attention );
}


1;
