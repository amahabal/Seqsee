# This track's each participant, known only by time.
package Experiment::Participant;
use strict;
use Class::Std;

my %ExtensionEncounters_of :ATTR(:get<extension_encounters>);

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    $ExtensionEncounters_of{$id} = {};
}

sub add_extension_encounter {
    my ( $self, $encounter ) = @_;
    $ExtensionEncounters_of{ident $self}{$encounter->get_presented_terms_string} = $encounter;
}

1;
