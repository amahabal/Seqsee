package SInt;
use 5.10.0;
use Class::Std;
use base qw{SInstance};

use overload 
    '+' => \&add_SInt,
    '-' => \&subtract_SInt,
    '""' => \&as_text;

my %mag_of :ATTR(:name<mag>);

sub add_SInt {
    my ( $f, $s ) = @_;
    my $s_mag = ref($s) ? $mag_of{ident $s} : $s;
    return SInt->new({mag => $mag_of{ident $f} + $s_mag});
}

sub subtract_SInt {
    my ( $f, $s, $is_reversed ) = @_;
    my $s_mag = ref($s) ? $mag_of{ident $s} : $s;
    my $f_mag = $mag_of{ident $f};
    my $new_mag = $is_reversed ? $s_mag - $f_mag : $f_mag - $s_mag;
    return SInt->new({mag => $new_mag});
}

sub as_text {
    my ( $self ) = @_;
    my $mag = $mag_of{ident $self};
    return "SInt($mag)";
}

1;
