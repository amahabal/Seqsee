package Compile::Seqsee;
use strict;
use Class::Std;
use Smart::Comments;


our $MULTILINE_BLOCK_START = qr/^ \s* < (\w+) > \s* $/x;
our $SINGLELINE_BLOCK = qr/^ \s* \[ (\w+) \] \s* (.*?) \s* $/x;
sub block_end_regexp{
    my ( $tag ) = @_;
    return qr/^ \s* < \/ $tag > \s* $/x;
}


my %unclaimed_lines_of :ATTR(:get<unclaimed_lines>);

sub pmc_compile{
    my ( $class, $src ) = @_;
    my $compiled = $class->parse($src);
    return $compiled->serialize;
}

sub parse{
    my ( $class, $src ) = @_;
    my @lines = split(/\n/, $src);
    my $object = new $class;
    while (@lines) {
        my $line = shift(@lines);
        $object->process_line($line, \@lines);
    }
    return $object;
}

sub process_line{
    my ( $object, $line, $lines_ref ) = @_;
    if ($line =~ $MULTILINE_BLOCK_START) {
        my $tag = $1;
        my $block = extract_block($tag, $lines_ref);
        $object->process_block($tag, $block);
    } elsif ($line =~ $SINGLELINE_BLOCK) {
        my ($tag, $block) = ($1, $2);
        $object->process_block($tag, $block);
    } else {
        $object->add_unclaimed($line . "\n");
    }
}

sub extract_block{
    my ( $tag, $lines_ref ) = @_;
    my $MULTILINE_BLOCK_END = block_end_regexp($tag);
    my $ret;
    while (@$lines_ref) {
        my $line = shift(@$lines_ref);
        if ($line =~ $MULTILINE_BLOCK_START) {
            die "Newsted blocks prohibited";
        } elsif ($line =~ $MULTILINE_BLOCK_END) {
            return $ret;
        } else {
            $ret .= "$line\n";
        }
    }
    return $ret;
}

sub process_block{
    my ( $object, $tag, $block ) = @_;
    my $handler = $object->can("handle_$tag");
    unless ($handler) {
        if ($object->can("DEFAULT_HANDLER")) {
            return $object->DEFAULT_HANDLER($tag, $block);
        }
        die "Don't know how to handle '$tag' blocks, and no DEFAULT_HANDLER";
    }
    $handler->($object, $block);
}

sub add_unclaimed{
    my ( $self, $line ) = @_;
    $unclaimed_lines_of{ident $self} .= $line;
}

1;


