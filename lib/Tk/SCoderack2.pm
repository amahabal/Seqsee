package Tk::SCoderack2;
use Tk::widgets qw{Frame MListbox};
use base qw/Tk::Derived Tk::Frame/;
use Smart::Comments;

our $UPDATABLE = 1;
Construct Tk::Widget 'SCoderack2';

our $list;
our $list_so_far;

sub Populate{
    my ( $self, $args ) = @_;
    $self->SUPER::Populate();

    my $column_specs = 
        [[-text => 'Family', -textwidth => 40],
         [-text => 'Count', -textwidth => 5],
         [-text => '% likelihood', -textwidth => 10],
         [-text => 'Urgencies', -textwidth => 35]
             ];
    $list = $self->MListbox(-height => 10, -columns => $column_specs)
        ->pack(-side => 'top');


    my $column_specs2 =
        [[-text => 'Type', -textwidth => 40],
         [-text => 'Count', -textwidth => 10],
         [-text => '%', -textwidth => 10]];
    $list_so_far = $self->MListbox(-height => 20, -columns => $column_specs2 )
        ->pack(-side => 'top');
}

sub Update{
    $list->delete('0.0', 'end');
    $list_so_far->delete('0.0', 'end');
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

    my $total_run_so_far = List::Util::sum(values %SCoderack::HistoryOfRunnable);
    if ($total_run_so_far) {
        foreach my $k (sort { $SCoderack::HistoryOfRunnable{$b} <=> $SCoderack::HistoryOfRunnable{$a}} keys %SCoderack::HistoryOfRunnable) {
            my $v = $SCoderack::HistoryOfRunnable{$k};
            $list_so_far->insert('end', [$k, $v, sprintf('%5.2f', 100 * $v / $total_run_so_far)]);
        }
    }

}

1;
