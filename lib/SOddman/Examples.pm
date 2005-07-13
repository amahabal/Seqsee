package SOddman::Examples;

sub new {
  my ( $package, $data, $test ) = @_;
  my $param_ref = {};
  my $counter = 0;
  for (@$data) {
    $counter++;
    $param_ref->{"seq_$counter"} = $_;
  }
  $counter = 0;
  for (@$test) {
    $counter++;
    $param_ref->{"test_$counter"} = $_;
  }
  return bless $param_ref, $package;
}

our $example_1 = new SOddman::Examples
  ( [ '3 4 5 6 5 4 3',
      '2 3 4 3 2',
      '8 9 8',
      '16 15 14',
      '3 4 3',
    ],
    [ '5 6 5',
      '8',
      '17 16 15'
    ]
  );

1;
