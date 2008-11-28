for my $filename (<performance/GraphSpecs/*>) {
    my $filename_copy = $filename;
    $filename_copy =~ s#GraphSpecs#generated_images#;
    $filename_copy .= '.eps';
    system "perl performance/PerfBarChart.pl --graph_spec=$filename --outfile=$filename_copy";
}
