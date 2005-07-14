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

our $example_2 = new SOddman::Examples
  (['1 2 3 ' ,
    '8 7 6 ' ,
    '1 2 3 4 ' ,
    '5 6 '
   ],

   []
  );
our $example_3 = new SOddman::Examples
  (['1 2 3 ' ,
    '3 4 5 ' ,
    '1 2 ' ,
    '1 2 3 4 5 6 '
   ],

   []
  );
our $example_4 = new SOddman::Examples
  (['1 2 3 4 3 2 1 ' ,
    '1 2 1 ' ,
    '3 4 3 ' ,
    '4 '
   ],

   []
  );
our $example_5 = new SOddman::Examples
  ([' 1 1 2 3' ,
    ' 1 2 3 3 3' ,
    ' 2 3 4' ,
    ' 1 1 2 3 3'
   ],

   []
  );
our $example_6 = new SOddman::Examples
  ([' 1 1 2 3' ,
    ' 7 7 8 9' ,
    ' 5 5 6 7 8 9' ,
    ' 4 5 5 6'
   ],

   []
  );
our $example_7 = new SOddman::Examples
  ([' 1 2 3 3 3 4' ,
    ' 1 1 1 2 3 4 5 6' ,
    ' 2 3 4 4 5 6' ,
    ' 2 3 4 5 5 6 7'
   ],

   []
  );
our $example_8 = new SOddman::Examples
  (['1 2 3 3 4 ' ,
    '8 9 10 10 11 ' ,
    '1 2 3 4 5 5 6 ' ,
    '5 6 6 7  8 9 '
   ],

   []
  );
our $example_9 = new SOddman::Examples
  ([' 1 2 3 3 4 ' ,
    ' 8 9 10 10 11' ,
    ' 3 3 4 5' ,
    ' 2 3 3 4 5 6 7 8'
   ],

   []
  );
our $example_10 = new SOddman::Examples
  ([' 1 1 2 3 3 ' ,
    ' 8 9 9 10 10 11 12' ,
    ' 7 7 8 9 10 11' ,
    ' 5 5 6 6'
   ],

   []
  );

1;
