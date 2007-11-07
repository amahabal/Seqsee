# This represents one person's response to one sequence.
package Experiment::Encounter;
use strict;
use Class::Std;
use Memoize;

my %Participant_of :ATTR(:name<participant>);
my %Sequence_of :ATTR(:name<sequence>);

my %PresentedTerms_of : ATTR(:name<presented_terms>);
my %PresentedTermsString_of :ATTR(:name<presented_terms_string>);
my %ExtesionDone_of : ATTR(:name<extension_by_user>);
my %TimeToUnderstand_of : ATTR(:name<time_to_understand>);
my %TypingTimes_of :ATTR(:name<typing_times>);

my %IsOutlier_of :ATTR(:get<is_outlier>, :set<is_outlier>);

1;
