package MyFilter;
use strict;
use SErr;
no warnings;

sub change{
  my ($sigil, $name, $arg, $next) = @_;
  $name ||= "self";
  if ($sigil eq '$') {
    return "\$$name". "->{$arg}$next" unless $next eq '(';
    return "\$$name"."->$arg(";
  }
  if ($sigil eq '&') {
    if ($next eq '(') {
      return "\$$name"."->$arg(";
    } else {
      die "When using &.name method call syntax, this must be followed by a '('. I see the syntax '$sigil$name.$arg$next', and I think it is an error";
    }
  } else {
    return "$sigil\{\$$name"."->\{$arg}}$next";
  }
}

sub change2{
  my $atts = shift;
  my @parts = split(/\s+/, $atts);
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
  $ret;
}

use Filter::Simple sub {
  my $what = $_;
  $what =~ s#([\$@%&])(\w*)\.(\w+)(.)#
    change($1, $2, $3, $4) #ge;

  $what =~ s#ATT\s*(.+);# change2($1)#ge;
  # print $what;
  $_ = $what;
};

1;
