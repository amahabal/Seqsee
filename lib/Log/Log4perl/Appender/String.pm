package Log::Log4perl::Appender::String;

use warnings;
use strict;

sub new{
    my ( $class, @options ) = @_;
    my $self = {
        
        @options,
            };
    bless $self, $class;
}

sub log{
    my ( $self, %params ) = @_;
    no strict;
    ${$self->{var}} .= $params{message};
}

1;

