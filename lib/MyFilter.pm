package MyFilter;
use strict;
use SErr;
no warnings;
use Filter::Simple sub {
  my $what = $_;
  $what =~ s/([\$@%&])(\w*)\.(\w+)/
	$1 eq '$' ? ($2 ? ("\$$2"."->{'$3'}") : "\$self->{'$3'}") : 
		($2 ? "$1\{\$$2"."->{'$3'}}" : "$1\{\$self->{'$3'}}")/ge;
  #return $what;
  $what =~ s#ATT\s*(.+);#     my @parts = split(/\s+/, $1);
    pop @parts unless $parts[-1];
    my $extra_ok = 0;
    if ($parts[-1] eq '*') {
      $extra_ok = 1;
      pop @parts;
    }
    my $ret = 'my %__args = @_;'. "\n";
    foreach my $p (@parts) {
      $ret .= "my \$$p = delete \$__args{$p} or die SErr::Att::Missing->throw(what => '$p');";
    }
    unless ($extra_ok) {
      $ret .= "SErr::Att::Extra->throw(what => [sort keys \%__args]) if \%__args;\n";
    }
    $ret#ge;
  # print $what;
  $_ = $what;
};

1;
