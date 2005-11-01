use strict;
use IO::Prompt;
use Template;

#


print "This is the tool to create a new thought family.\n";

my $familyname = prompt "Name of thought type: ", -require => { 'Name of thought type should only have a-zA-Z_' => qr{^[a-zA-Z][a-zA-Z_]+$} };
    
my $filename = "lib/SThought/$familyname.pm";

if (-e $filename) {
    die "File $filename already exists: won't overwrite!";
}

my $has_core = prompt "Does this class have a core? ", "-yn";

my $proceed = prompt "About to begin file writing. Proceed? ", "-yn";

if ($proceed) {
    my $template = Template->new({ INCLUDE_PATH => '/u/amahabal/SeqseeTree/summer05/templates', OUTPUT => $filename, OUTPUT_PATH => "."});
    my $vars = {
        ThoughtType => "$familyname",
        has_core    => $has_core,
            };
    $template->process("ThoughtPM.tt", $vars) || die $template->error;
} 

if (prompt "Add this to SVN? ", "-yn") {
    system "svn add $filename";
}

if (prompt "Add this to ThoughtType.list? ", "-yn") {
    open OUT, ">>ThoughtType.list";
    print OUT "SThought::$familyname\n";
    close OUT;
}
