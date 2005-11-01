use strict;
use IO::Prompt;
use Template;

#


print "This is the tool to create a new codelet family.\n";

my $familyname = prompt "Name of codefamily: ", -require => { 'Name of codefamily should only have a-zA-Z_' => qr{^[a-zA-Z][a-zA-Z_]+$} };
    
my $filename = "lib/SCF/$familyname.pm";

if (-e $filename) {
    die "File $filename already exists: won't overwrite!";
}

my $use_multis = prompt "Do you think you will use multimethods in this codelet? [yn] ", '-yn';


my $proceed = prompt "About to begin file writing. Proceed? ", "-yn";

if ($proceed) {
    my $template = Template->new({ INCLUDE_PATH => '/u/amahabal/SeqseeTree/summer05/templates', OUTPUT => $filename, OUTPUT_PATH => "."});
    my $vars = {
        FamilyName => "$familyname",
        multimethods => $use_multis,
        description => ""
            };
    $template->process("CodeletPM.tt", $vars) || die $template->error;
} 

if (prompt "Add this to SVN? ", "-yn") {
    system "svn add $filename";
}

if (prompt "Add this to SCF.list? ", "-yn") {
    open OUT, ">>SCF.list";
    print OUT "SCF::$familyname\n";
    close OUT;
}
