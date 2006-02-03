#####################################################
#
#    Package: SReln::Simple
#
#####################################################
#   Package for maintianing simple relations between integers.
#####################################################

package SReln::Simple;
use strict;
use Carp;
use Class::Std;
use Class::Multimethods;
use base qw{SReln};
use Smart::Comments;

# variable: %str_of
#    The string representation of the relation
my %str_of :ATTR(:get<text>);

# variable: %first_of
#    The first of the two things the relation is between
my %first_of :ATTR( :get<first>);

# variable: %second_of
#    The second
my %second_of :ATTR( :get<second>);


# method: BUILD
# Builds.
#
#    Just needs the text. But maybe should also need the two objects. XXX probably change that!

sub BUILD{
    my ( $self, $id, $arg_ref ) = @_;
    $str_of{$id} = $arg_ref->{text} or confess "Need text!";
    
    $first_of{$id}  = $arg_ref->{first} if $arg_ref->{first};
    $second_of{$id} = $arg_ref->{second} if $arg_ref->{second};

}



# multi: find_reln ( #, # )
# Relation between two numbers
#
#    This one is simple: can be same, succ, pred or nothing
#     
#    Feels like I am writing this for the 100th time!
#
#    usage:
#     
#
#    parameter list:
#
#    return value:
#      
#
#    possible exceptions:

multimethod find_reln => ('#', '#') => sub {
    my ( $a, $b ) = @_;
    if ($a == $b) {
        return SReln::Simple->new( { text => "same", 
                                     first => $a,
                                     second => $b,
                                 });
    } elsif ($a + 1 == $b ) {
        return SReln::Simple->new( { text => "succ",
                                     first => $a,
                                     second => $b,
                                 });
    } elsif ($a - 1 == $b) {
        return SReln::Simple->new( { text => "pred",
                                     first => $a,
                                     second => $b,
                                 });
    }

    return;
};



# multi: apply_reln ( SReln::Simple, # )
# Apply a simple relation to an integer
#
#
#    usage:
#     
#
#    parameter list:
#
#    return value:
#      
#
#    possible exceptions:

multimethod apply_reln => ('SReln::Simple', '#')=> sub {
    my ( $reln, $num ) = @_;
    my $text = $str_of{ident $reln};

    if ($text eq "same") {
        return $num;
    } elsif ($text eq "succ") {
        return $num + 1;
    } elsif ($text eq "pred") {
        return $num - 1;
    } else {
        confess "Reln not applicable to num";
    }

};

#
# subsection: SElements



# multi: find_reln ( $, $ )
# Both must be integers, else dies
#
multimethod find_reln => ('$', '$') => sub {
    my ( $n1, $n2 ) = @_;
    print "Should Never reach here; If it does, it means that find_reln was called with funny arguments. These, in this case, are:\n\t'$n1'\n\t'$n2'\n";
    confess "find_reln error";
};




# multi: find_reln ( SElement, SElement )
# merely the relation between their magnitudes
#
multimethod find_reln => qw( SElement SElement ) => sub {
    my ( $e1, $e2 ) = @_;
    my $rel = find_reln($e1->get_mag(), $e2->get_mag);
    if ($rel) {
        my $id = ident $rel;
        $first_of{$id} = $e1;
        $second_of{$id} = $e2;
    }
    return $rel;
};



# multi: apply_reln ( SReln::Simple, SElement )
# 
multimethod apply_reln => qw(SReln::Simple SElement) => sub {
    my ( $rel, $el ) = @_;
    my $new_mag = apply_reln($rel, $el->get_mag());
    # Need to return an selement, but unanchored. Sigh.
    return SElement->create( $new_mag, 0 );
};

sub as_text{
    my ( $self ) = @_;
    return $self->get_text;
}



# multi: are_relns_compatible ( SReln::Simple, SReln::Simple )
# yes/no reply. Compatible if they are the same
#
multimethod are_relns_compatible => qw{SReln::Simple SReln::Simple} => sub {
    my ( $r1, $r2 ) = @_;
    return $r1->get_text() eq $r2->get_text();
};



# method: suggest_cat
# suggests a cat type based on reln
#
sub suggest_cat{
    my ( $self ) = @_;
    my $id = ident $self;
    my $str = $str_of{$id};

    if ($str eq "same") {
        return $S::SAMENESS;
    } elsif ($str eq "succ") {
        return $S::ASCENDING;
    } elsif ($str eq "pred") {
        return $s::DESCENDING;
    }

}

sub as_insertlist{
    my ( $self, $verbosity ) = @_;
    my $id = ident $self;

    if ($verbosity == 0) {
        return new SInsertList( $self->as_text() );
    }

    if ($verbosity == 1) {
        my $list = new SInsertList;
        $list->append($self->as_text(), "", "\n");
        $list->append("first: ", "first_second", "\n");
        ## $list
        ## $first_of{$id}->as_insertlist(0)
        ## $first_of{$id}->as_insertlist(0)->indent(1)

        $list->concat( $first_of{$id}->as_insertlist(0)->indent(1) );
        
        $list->append("Second: ", "first_second", "\n");
        $list->concat( $second_of{$id}->as_insertlist(0)->indent(1) );
        $list->append("\n");
        return $list;
    }

    if ($verbosity == 2) {
        my $list = new SInsertList;
        $list->append($self->as_text(), "", "\n");
        $list->append("first: ", "first_second", "\n");
        $list->concat( $first_of{$id}->as_insertlist(1)->indent(1) );

        $list->append("Second: ", "first_second", "\n");
        $list->concat( $second_of{$id}->as_insertlist(1)->indent(1) );
        $list->append("\n");
        return $list;
    }

    die "Verbosity $verbosity not implemented for ". ref $self;
}



1;


