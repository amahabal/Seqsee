package Tk::SInfo;
use Tk::widgets qw{ROText};
use base qw/Tk::Derived Tk::ROText/;

my %tags_for_type = (
    ''                 => [],
    'codelet_added'    => ['codelet_added'],
    'thought_scheduled'=> ['thought_added'],
    'thought_forced'   => ['thought_added'],
    'fringe'           => ['fringe'],
    'heading'          => ['heading'],
        );

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

sub insert_autoTagged{
    my ( $self, $where, @rest ) = @_;
    my @to_insert;
    for my $str (@rest) {
        my @lines = split /\n/, $str;
        for my $line (@lines) {
            push @to_insert, $line, classify_and_tag($line), "\n", "";
        }
    }
    $self->insert($where, @to_insert);
}

sub classify_and_tag{
    my ( $line ) = @_;
    my $classification = classify($line);
    return $tags_for_type{$classification};
}

sub classify{
    my ( $line ) = @_;
    if ($line =~ qr{^:\s*(\S+)}) {
        my $first_word = $1;
        return $first_word eq "codelet"   ? "codelet_added" :
               $first_word eq "scheduled" ? "thought_scheduled" :
               $first_word eq "forced"    ? "thought_forced" :
                   "";
    }
    if ($line =~ qr{^\s*-}) {
        return "fringe";
    }
    if ($line =~ qr{^===\s*\d+}) {
        return "heading";
    }
    return '';
}


1;
