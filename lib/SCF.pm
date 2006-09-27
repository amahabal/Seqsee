#####################################################
#
#    Package: SCF
#
#####################################################
#####################################################

package SCF;
use strict;
use Carp;
use Class::Std;
use base qw{Exporter};

our @EXPORT = qw( ContinueWith NeedMoreData );

sub ContinueWith {
    my ($runnable) = @_;
    SErr::ContinueWith->new( payload => $runnable )->throw;
}

sub NeedMoreData {
    my ($runnable) = @_;
    SErr::NeedMoreData->new( payload => $runnable )->throw;
}

1;
