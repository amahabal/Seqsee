use strict;
use Config::Std;
use Carp;
use List::Util qw(sum);
use Smart::Comments;

use OLE;
use Win32::OLE::Const 'Microsoft.Excel';    # wd  constants
use Win32::OLE::Const 'Microsoft Office';  # mso constants

sub CreateSheetForSequence{
    my ( $workbook, $sequence, $data ) = @_;
    $workbook->Sheets()->Add();
    my $sheet = $workbook->ActiveSheet();

    my $row_count = scalar(@$data);
    my $data_range = 'A3:D' . ($row_count + 2);

    $sheet->{'Name'} = $sequence;
    $sheet->Range($data_range)->{'Value'} = $data;
    my $table = $sheet->{ListObjects}->Add(1, #xlsrcrange
                                           $sheet->Range($data_range),
                                           ,
                                           2, # xlNo
                                               );

    my $label_range = $sheet->Range('C1');
    $label_range->{Font}->{Size} = 20;
    $label_range->{Font}->{Bold} = 1;
    $label_range->{Font}->{ColorIndex} = 3;
    $label_range->{Value} = $sequence;


    my $chart_object = $workbook->ActiveSheet->ChartObjects()->Add(240, 20, 230, 160);
    my $chart = $chart_object->{"Chart"};
    $chart->SetSourceData($sheet->Range('D4:D' . ($row_count + 3)));
    $chart->{ChartType} = 4; # Line
    $chart->{ChartStyle} = 4;

    my $second_chart_object = $workbook->ActiveSheet->ChartObjects()->Add(240, 200, 230, 160);
    my $chart2 = $second_chart_object->{Chart};
    my $axis = $chart2->Axes(1); # xlCategory => 1
    $axis->{CategoryNames} = $sheet->Range('A4:A7');
    $chart2->SetSourceData($sheet->Range('B4:C' . ($row_count + 3)));
    $chart2->{ChartType} = 76; #AreaStacked
    $chart2->{ChartStyle} = 4;
}

my $outfile   = "excel_output.pdf";

my $output_core;

{
    my $excel = CreateObject OLE 'Excel.Application' or die $!;
    $excel->{'Visible'} = 1;
    
    my $workbook = $excel -> Workbooks -> Add;
    my @files = glob("Reg/*.reg.log_res");
    for (@files) {
        process_single_seq( $_, $workbook );
    }
    $workbook->ExportAsFixedFormat(0, $outfile);
}

sub process_single_seq {
    my ( $file, $workbook ) = @_;
    my @list;

    $file =~ m#(\w+).reg.log_res$# or confess "Huh?";
    my $seq_name = $1;
    $seq_name =~ s#_# #g;

    my $seq_file = $file;
    $seq_file =~ s#.log_res$##;
    read_config $seq_file => my %opts;
    %opts = %{ $opts{''} };
    my ( $seq, $ext ) = split( /\|/, $opts{seq} );
    @opts{'seq', 'ext'} = ($seq, $ext);

    while (my($k, $v) = each %opts) {
        $k =~ s#_# #g;
        #$out_str_table .= "$k & $v \\\\\n";
    }
    #$out_str_table .= '\end{tabular}';

    read_config $file => my %opts2;
    delete $opts2{''};
    my @times = sort { $b <=> $a }keys %opts2;
    for my $time (@times) {
        my %opts = %{$opts2{$time}};
        my @result = (
            10 * ($opts{GotIt}           ||= 0),
            10 * ($opts{BlemishedGotIt}  ||= 0),
            10 * ($opts{Extended}        ||= 0),
            10 * ($opts{NotEvenExtended} ||= 0)
        );
        push @result, 100 - sum(@result);
        unshift @result, timestring($time);
        # Now @result has: $time, $GotIt $BlemishedGotIt $Extended $NotEvenExtended $Died
        my @result_subset = (@result[0, 1, 5],
                             0, # of codelets; don't yet have data
                                 );
        push @list, \@result_subset;
    }
    $seq_name =~ s#_# #g;
    CreateSheetForSequence($workbook, $seq, \@list);
}

sub timestring{
    my ( $time ) = @_;
    my $string = localtime($time);
    return $string;
}

