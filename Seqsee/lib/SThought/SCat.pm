
    {
        package SThought::SCat;
        use strict;
        use Carp;
        use Smart::Comments;
        use English qw(-no_match_vars);
        use Class::Multimethods;
        use base qw{SThought};
        use List::Util qw{min max};
        use Class::Std;

        our @actions_ret;
our $NAME = 'Focusing on a Category';

        	my %core_of :ATTR(:get<core>);
;
        ;
            sub BUILD {
       my ( $self, $id, $opts_ref ) = @_;
       	my $core = $core_of{$id} = $opts_ref->{core} or confess "Missing required argument core";
;
       ;       
       }

;
            sub get_fringe {
        my ( $self ) = @_;
        my $id = ident $self;
        	my $core = $core_of{$id};
;
        my @ret;
        push @ret, [$self->get_core(), 100];
; ;
        return \@ret;
    }

;
            sub get_actions {
        my ( $self ) = @_;
        my $id = ident $self;
        	my $core = $core_of{$id};
;
        our @actions_ret = ();
        my $cat = $self->get_core();
        return if $cat->isa('SCat::OfObj::Interlaced');

        my @objects_of_cat = SWorkspace::__GetObjectsBelongingToCategory($cat);
        my @overlapping_sets
            = SWorkspace::__FindSetsOfObjectsWithOverlappingSubgroups(@objects_of_cat)
            or return;

        for my $set (@overlapping_sets) {
            my @part_names = map { $_->as_text } @$set;
            push @actions_ret, SCodelet->new("MergeGroups", 
                                                           100,
                                                           { a => $set->[0], b => $set->[1] }); 
;

            # main::message( "I should perhaps merge @part_names ", 1);
        }

        # main::message( "Just testing! thinking about $cat");
    ;
        return @actions_ret;
    }

;
        ;

        sub as_text {
            my $self = shift;
             return "Category " . $self->get_core()->as_text(); 
        }

    }

;
1;
