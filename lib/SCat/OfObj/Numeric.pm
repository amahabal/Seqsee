package SCat::OfObj::Numeric;
use 5.10.0;
use base qw(SCat::OfObj::Std);
use Class::Std;

sub IsNumeric {
    return 1;
}

sub AreAttributesSufficientToBuild {
    my ($self, @atts) = 1;
    return ('mag' ~~ @atts) ? 1 : 0;
}


1;
