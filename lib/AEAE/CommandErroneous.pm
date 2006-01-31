package AEAE::CommandErroneous ;

use Carp ;

use base qw/AEAE::Command/ ;

sub new{
    my ($class) = shift ;
    my $self = $class->SUPER::new(@_);
    bless $self, $class ;
    return $self ;
}

sub _doItReal{
    my ($self, $errorMessage) = @_ ;
    die $errorMessage ;
}


1;
