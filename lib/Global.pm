package Global;

our $Steps_Finished;
our $Break_Loop;
our $CurrentCodelet;
our $CurrentCodeletFamily;
our $CurrentRunnableString;
our $AtLeastOneUserVerification;
our $TestingOptionsRef;
our $TestingMode;
our %ExtensionRejectedByUser;
our $LogString = '';


sub clear{
    $Steps_Finished = 0;
    $AtLeastOneUserVerification = 0;
    %ExtensionRejectedByUser = ();
}

1;
