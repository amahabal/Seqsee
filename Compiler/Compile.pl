use strict;
use File::Slurp qw{slurp write_file};
use File::Basename;
use File::Path;
use Smart::Comments;
use Parse::RecDescent;

use Compiler::Filters::Formula;
Compiler::Filters::Formula->ReadFormulaFile('sample_formulas');

use Compiler::Filters::CodeletFamily;
use Compiler::Filters::ThoughtType;

my @FILTERS;
push @FILTERS, Compiler::Filters::Formula::GetFilter();
push @FILTERS, Compiler::Filters::CodeletFamily::GetFilter();
push @FILTERS, Compiler::Filters::ThoughtType::GetFilter();


sub CompileAllFiles {
    for my $file (glob('lib/*.pm lib/*/*.pm lib/*/*/*.pm')) {
        CompileFile($file);
    }
}

sub CompileFile {
    my ($filename) = @_;
    my $stripped_filename = substr( $filename, 4 );
    my $compiled_filename = "genlib/$stripped_filename";
    if ( not( -e $compiled_filename ) or ( -M $filename ) < ( -M $compiled_filename ) ) {
        ## filenames: $filename, $stripped_filename, $compiled_filename
        DoActualCompile( $filename, $compiled_filename );
    }
}

sub DoActualCompile {
    my ( $source_file, $target_file ) = @_;
    my $original_source = slurp($source_file);
    my $source = $original_source;
    for my $filter (@FILTERS) {
        $source = $filter->($source);
    }
    my ($name, $path, $suffix) = fileparse($target_file);
    if (not(-e $path)) {
        ## Path needs creating: $name, $path, $suffix
        mkpath($path);
    }
    write_file( $target_file, $source );
    unless ($source eq $original_source) {
        print "FILE MODIFIED BY FILTER: $source_file\n";
    }
}

CompileAllFiles();
