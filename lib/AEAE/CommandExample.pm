package AEAE::CommandExample ;

use Carp;
use base qw/AEAE::Command/;

use strict ;

=head1 NAME
    
AEAE::CommandExample - A command to test the module.

=cut

=head2 new

Returns a new instance of this command.

=cut

sub new{
    my ($class) = shift ;
    
    my $self = $class->SUPER::new(@_);
    bless $self, $class ;
    return $self ;
}



=head2 _doItReal

Actually do something useless.

=cut

sub _doItReal{
    my $self = shift ;
    my $mustDie = shift ;
    my $i = 0 ;

    print "Let us start !\n";
    local $| = 1 ;
    while( $i < 101){
	
	$AEAE::Command::processCommand->oneStep($i);
	print STDERR "We are here:".$i."\n";
	print STDOUT "Step ".$i."\n";
	$i += 5 ;
	sleep(1);
	if( ( $i > 70 ) && $mustDie){ confess( "An horrible error" );}
    }
    print "Now its over!\n";
}

=head2 _killHandler

Last words ...

=cut

sub _killHandler{
    my ($self) = @_;
    print "ARGGGG I DIED\n";
 
    #close STDOUT ;
    #close STDERR ;
}


1;
