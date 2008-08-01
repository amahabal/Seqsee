package TestOutputStatus;
use Class::Std::Storable;
my %status_string_of : ATTR(:name<status_string>);
our $Successful      = new TestOutputStatus( { status_string => 'Successful' } );
our $RanOutOfTerms   = new TestOutputStatus( { status_string => 'RanOutOfTerms' } );
our $InitialBlemish  = new TestOutputStatus( { status_string => 'InitialBlemish' } );
our $ExtendedABit    = new TestOutputStatus( { status_string => 'ExtendedABit' } );
our $NotEvenExtended = new TestOutputStatus( { status_string => 'NotEvenExtended' } );
our $Crashed         = new TestOutputStatus( { status_string => 'Crashed' } );

print "Crashed=$Crashed\n";

sub IsSuccess {
    my ($self) = @_;
    return ( $self->get_status_string eq 'Successful' ) ? 1 : 0;
}

sub IsAtLeastAnExtension {
    my ($self) = @_;
    my $status_string = $self->get_status_string;
    for ( qw{Successful RanOutOfTerms InitialBlemish ExtendedABit} ) {
        return 1 if $status_string eq $_;
    }
    return 0;
}

sub IsACrash {
    my ($self) = @_;
    return ( $self->get_status_string eq 'Crashed' ) ? 1 : 0;
}

package ResultOfTestRun;
use Class::Std::Storable;
my %OutputStatus_of : ATTR(:name<status>);
my %StepsTaken_of : ATTR(:name<steps>);
my %ErrorMessage_of : ATTR(:name<error>);

package ResultsOfTestRuns;
use Class::Std::Storable;
my %Wallclockimes_of :ATTR(:name<times>);
my %Results_of :ATTR(:name<results>);
my %Rates_of :ATTR(:name<rate>);
my %Terms_of :ATTR(:name<terms>);
my %Features_of :ATTR(:name<features>);
my %Version_of :ATTR(:name<version>);
1;
