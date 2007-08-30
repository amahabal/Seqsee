package Tk::Strength2;
use Tk::widgets qw{Frame MListbox};
use base qw/Tk::Derived Tk::Frame/;
use Smart::Comments;

my $list;

our $UPDATABLE = 'OnRaise';
our $LAST_UPDATE = -1;
Construct Tk::Widget 'Strength2';

my $NumericSort = sub {
    return $_[0] <=> $_[1];
};


sub Populate{
    my ( $self, $args ) = @_;
    my $tags_ref = delete $args->{-tags_provided};
    $self->SUPER::Populate( );
    my $column_specs = [[-text => 'Type', -textwidth => 15],
                        [-text => 'As string', -textwidth => 40],
                        [-text => 'Strength', -textwidth => 10],
                        [-text => 'Effectively', -textwidth => 20]];
    $list = $self->MListbox(-height => 30, -columns => $column_specs)
        ->pack(-side => 'top');
}

sub clear{
    $list->delete('0.0', 'end');    
}

sub Update{
    $list->delete('0.0', 'end');
    for my $object (SWorkspace::GetElements(), values %SWorkspace::groups,
                        values %SWorkspace::relations) {
        my $type = ref $object;
        my $string = $object->as_text;
        my $strength = $object->get_strength();
        my $effectively = '-';
        if ($object->isa('SObject')) {
            my $metonym = $object->get_metonym();
            if ($metonym) {
                # XXX(Board-it-up): [2006/12/20] Fix

            }
        }
        $list->insert('end', [$type, $string, $strength, $effectively]);

    }

}


1;
