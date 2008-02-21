#####################################################
#
#    Package: SRelnType::Simple
#
#####################################################
#####################################################

package SRelnType::Simple;
use 5.10.0;
use strict;
use Carp;
use Class::Std;
use Class::Multimethods;
use base qw{SRelnType};

my %string_of : ATTR(:get<text>);
my %direction_reln_of : ATTR(:get<direction_reln>);    # Unused, for compatibility with compond
my %category_of :ATTR(:get<category>); # for prime successor, etc.

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    $string_of{$id} = $opts_ref->{string};
    $category_of{$id} = $opts_ref->{category} // 0;

    # XXX(Board-it-up): [2006/11/01] Need a class Reln::Dir or some such
    $direction_reln_of{$id} = $SReln::Dir::Unknown;
}

{
    my %MEMO = ();

    sub create {
        my ( $package, $string, $category ) = @_;
        $category //= 0;
        return $MEMO{SLTM::encode($string, $category)} ||= $package->new( { string => $string,
                                                               category => $category,
                                                           } );
    }

    sub resuscicate {
        my ( $package, $string,  $category) = @_;
        return $package->create($string, $category);
    }

}

sub get_type { $_[0] }

sub as_text {
    my ($self) = @_;
    my $id = ident $self;
    my $cat = $category_of{$id};
    if ($cat) {
        return $string_of{$id} . ' of ' . $cat->get_name;
    } else {
        return $string_of{$id};
    }
}

sub serialize {
    my ($self) = @_;
    my $id = ident $self;
    return SLTM::encode($string_of{$id}, $category_of{$id});
}

sub deserialize {
    my ( $package, $str ) = @_;
    $package->create(SLTM::decode($str));
}

sub get_memory_dependencies {
    my $cat = $category_of{ident $_[0]};
    return $cat if $cat;
    return;
}

multimethod apply_reln => ( 'SRelnType::Simple', '#' ) => sub {
    my ( $reln, $num ) = @_;
    my $text = $string_of{ ident $reln};
    my $cat = $category_of{ident $reln};

    if ($cat) {
        return $cat->ApplyRelationType($reln, $num);
    }

   # say "This apply_reln still used!";
    if ( $text eq "same" ) {
        return $num;
    }
    elsif ( $text eq "succ" ) {
        return $num + 1;
    }
    elsif ( $text eq "pred" ) {
        return $num - 1;
    }
    else {
        confess "Reln not applicable to num";
    }

};

{
my $apply_reln = sub {
    my ( $rel, $el ) = @_;
    my $cat = $category_of{ident $rel};

    if ($cat) {
        return $cat->ApplyRelationType($rel, $el);
    }

    my $new_mag = apply_reln( $rel, $el->get_mag() );
    #say "This (SElement) apply_reln still used!";

    # Need to return an selement, but unanchored. Sigh.
    my $ret = SElement->create( $new_mag, 0 );

    my $rel_dir = $rel->get_direction_reln;
    my $obj_dir = $el->get_direction;
    my $new_dir = apply_reln( $rel_dir, $obj_dir );

    $ret->set_direction($new_dir);

    return $ret;
};
multimethod apply_reln => qw(SRelnType::Simple SElement) => $apply_reln;
multimethod apply_reln => qw(SRelnType::Simple SInt) => $apply_reln;
}
multimethod apply_reln => qw(SRelnType::Simple SAnchored) => sub {
    return;
};
# method: suggest_cat
# suggests a cat type based on reln
#
sub suggest_cat {
    my ($self) = @_;
    my $id     = ident $self;
    my $str    = $string_of{$id};
    my $cat = $category_of{$id};

    if ($cat) {
        return SCat::OfObj::RelationTypeBased->Create($self);
    }
    if ( $str eq "same" ) {
        return $S::SAMENESS;
    }
    elsif ( $str eq "succ" ) {
        return $S::ASCENDING;
    }
    elsif ( $str eq "pred" ) {
        return $S::DESCENDING;
    }

}

sub suggest_cat_for_ends{
    my ( $self ) = @_;
    return;
}

my %ComplexityLookup = qw{same 1 succ 0.9 pred 0.9};
sub get_complexity_penalty {
    my ( $self ) = @_;
    my $string = $string_of{ident $self};
    return $ComplexityLookup{$string} || die;
}

sub IsEffectivelyASamenessRelation {
    my ( $self ) = @_;
    return $string_of{ident $self} eq 'same' ? 1 : 0;
}

sub get_complexity_penalty {
    return 1;
}


1;

