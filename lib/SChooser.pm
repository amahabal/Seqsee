package SChooser;
use strict;
use Carp;

our $NULL = SChooser::NULL->create();

sub create{
  my $package = shift;
  my $what = shift;
  return $NULL unless $what;
  my $ref = ref $what;
  return SChooser::ByName->create($what) unless $ref;
  if ($ref =~ /^Chooser/) {
    return $what;
  } elsif ($ref eq "CODE") {
    return SChooser::BySub->create($what);
  }
}

package SChooser::NULL;
use strict;
use Carp;
our @ISA = qw{SChooser};

sub create{
  bless [], shift;
}

sub choose{
  my $self = shift;
  my $sum  = scalar(@_);
  confess "choose called with nothing to choose from" unless $sum;
  my $rand = int( $sum * rand() );
  return $_[$rand];  
}

sub choose_safe{
  my $self = shift;
  my $sum  = scalar(@_);
  return undef unless $sum;
  my $rand = int( $sum * rand() );
  return $_[$rand];  
}


package SChooser::BySub;
use strict;
use Carp;
our @ISA = qw{SChooser};

sub create{
  my $package = shift;
  my $sub = shift;
  bless $sub, $package;
}

sub choose{
  my $chooser_sub  = shift;
  my @items        = @_;
  confess "choose_on_sub called with nothing to choose from" unless @items;
  my ( $sum, $val, $rand, @vals );
  @vals = map { $val = &{$chooser_sub}($_); $sum += $val; $val } @items;
  unless ($sum) {
    return $SChooser::NULL->choose(@items);
  }
  $rand = $sum * rand();
  $val  = 0;
  while ( $rand >= 0 ) {
    $rand -= $vals[$val];
    $val++;
  }
  return $items[ $val - 1 ];
}

sub choose_safe{
  my $chooser_sub  = shift;
  my @items        = @_;
    return undef unless @items;
  my ( $sum, $val, $rand, @vals );
  @vals = map { $val = &{$chooser_sub}($_); $sum += $val; $val } @items;
  unless ($sum) {
    return $SChooser::NULL->choose(@items);
  }
  $rand = $sum * rand();
  $val  = 0;
  while ( $rand >= 0 ) {
    $rand -= $vals[$val];
    $val++;
  }
  return $items[ $val - 1 ];
}

package SChooser::ByName;
use strict;
use Carp;
our @ISA = qw{SChooser};

sub create{
  my $package = shift;
  my $name    = shift;
  return $SChooser::NULL unless $name;
  bless \$name, $package;
}

sub choose{
  my $self    = shift;
  my $chooser = $$self;
  my @items = @_;
  confess "choose_on called with nothing to choose from" unless @items;
  my ( $sum, $val, $rand, @vals );
  @vals = map { $val = $_->{f}{$chooser}; $sum += $val; $val } @items;
  unless ($sum) {
    return $SChooser::NULL->choose(@items);
  }
  $rand = $sum * rand();
  $val  = 0;
  while ( $rand >= 0 ) {
    $rand -= $vals[$val];
    $val++;
  }
  return $items[ $val - 1 ];
}

sub choose_safe{
  my $self = shift;
  my $chooser = $$self;
  my @items = @_;
  return undef unless @items;
  my ( $sum, $val, $rand, @vals );
  @vals = map { $val = $_->{f}{$chooser} || 0; $sum += $val; $val } @items;
  unless ($sum) {
    return $SChooser::NULL->choose(@items);
  }
  $rand = $sum * rand();
  $val  = 0;
  while ( $rand >= 0 ) {
    $rand -= $vals[$val];
    $val++;
  }
  return $items[ $val - 1 ];
}


package SChooser::ByWt;
use strict;

sub choose{
  my $package = shift;
  my ($obj_ref, $wt_ref) = @_;
  my $sum = 0; foreach (@$wt_ref) { $sum += $_ }
  return undef unless $sum;
  my $rand = $sum * rand();
  my $val  = 0;
  while ( $rand >= 0 ) {
    $rand -= $wt_ref->[$val];
    $val++;
  }
  return $obj_ref->[ $val - 1 ];
}

1;
