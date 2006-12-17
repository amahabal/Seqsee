package Tk::SCoderack2;
use Tk::widgets qw{Frame MListbox};
use base qw/Tk::Derived Tk::Frame/;
use Smart::Comments;

our $UPDATABLE = 1;
Construct Tk::Widget 'SCoderack2';

our $list;

sub Populate{
    my ( $self, $args ) = @_;
    $self->SUPER::Populate();

    my $column_specs = 
        [[-text => 'Family', -textwidth => 40],
         [-text => 'Count', -textwidth => 5],
         [-text => '% likelihood', -textwidth => 10],
         [-text => 'Urgencies', -textwidth => 35]
             ];
    $list = $self->MListbox(-height => 20, -columns => $column_specs)
        ->pack(-side => 'top');

}

sub Update{
    $list->delete('0.0', 'end');
    my %count;
    my %sum;
    my %urgencies;
    for my $cl (@SCoderack::CODELETS) {
        my $family = $cl->[0];
        my $urgency = $cl->[1];
        $count{$family}++;
        $sum{$family}+= $urgency;
        push @{$urgencies{$family}}, $urgency;
    }

    if (my $usum = $SCoderack::URGENCIES_SUM) {
        for (values %sum) {
            $_ /= $usum * 0.01;
        }
    } else {
        for (values %sum) {
            $_ = '---';
        }
    }

    for (keys %count) {
        $list->insert('end', [$_, $count{$_}, $sum{$_}, join(', ', @{$urgencies{$_}})])
    }
}

1;
