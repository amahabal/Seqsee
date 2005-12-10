package Tk::SInfo;
use Tk::widgets qw{ROText};
use base qw/Tk::Derived Tk::ROText/;

my $list;

Construct Tk::Widget 'SInfo';

sub Populate{
  my ( $self, $args ) = @_;
  my $tags_ref = delete $args->{-tags_provided};
  $list = $self;
  $self->SUPER::Populate( $args );
  for (@$tags_ref) {
      $self->tagConfigure(@$_);
  }

  $self->tagBind('clickable', 
                  '<1>' => sub {
                     my $self = shift;
                     my @names = $self->tagNames('current');
                     # print join(", ", @names), "\n";
                     my ($name) = grep { m/^S/ } @names;
                     # print "You clicked", $name, "\n";
                     print $SStream::vivify{$name}->as_text(), "\n";
                 });
}


sub clear{
  $list->delete('0.0', 'end');
}

sub Display{
    my $self = shift;
    $list->delete('0.0', 'end');
    my @insert_array;
    my $last_seen_was_non_tag = 0;
    while (@_) {
        my $next = shift;
        if ($last_seen_was_non_tag) {
            # expecting a tag
            if (ref($next) eq "ARRAY") {
                # got a tag
                push @insert_array, $next;
                $last_seen_was_non_tag = 0;
            } else {
                push @insert_array, [], $next;
                $last_seen_was_non_tag = 1;
            }
        } else {
            push @insert_array, $next;
            $last_seen_was_non_tag = 1;
        }
    }
    $self->insert('end', @insert_array);
}

sub Update{

}


1;
