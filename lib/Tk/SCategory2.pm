package Tk::SCategory2;
use Tk::widgets qw{Frame MListbox};
use base qw/Tk::Derived Tk::Frame/;
use Smart::Comments;

my $list;

our $UPDATABLE = 'OnRaise';
our $LAST_UPDATE = -1;
Construct Tk::Widget 'SCategory2';

my $NumericSort = sub {
    return $_[0] <=> $_[1];
};


sub Populate{
    my ( $self, $args ) = @_;
    my $tags_ref = delete $args->{-tags_provided};
    $self->SUPER::Populate( );
    my $column_specs = [[-text => 'Name', -textwidth => 60],
                        [-text => '# instances', -textwidth => 10]];
    $list = $self->MListbox(-height => 20, -columns => $column_specs)
        ->pack(-side => 'top');
}

sub clear{
    $list->delete('0.0', 'end');    
}

sub Update{
    $list->delete('0.0', 'end');
    my %category_counts;
    for my $object (SWorkspace::GetElements(), values %SWorkspace::groups) {
        for (@{ $object->get_categories() }) {
            $category_counts{$_}++;
        }
    }

    for (keys %category_counts) {
        $list->insert('end', [$_, $category_counts{$_}]);
    }
}


1;
