package AEAE::CommandErroneous ;

use Carp ;

use base qw/AEAE::Command/ ;
use strict ;

=head1 NAME

AEAE::CommandErroneous - A command used when an error occur at launching another command.

=cut

=head2 new

Returns a new instance ...

=cut

sub new{
    my ($class) = shift ;
    my $self = $class->SUPER::new(@_);
    bless $self, $class ;
    return $self ;
}

=head2 _doItReal

Dies with the given error message.

=cut

sub _doItReal{
    my ($self, $errorMessage) = @_ ;
    die $errorMessage ;
}


1;
