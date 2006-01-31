package AEAE::CommandExample ;

use Carp;

use base qw/AEAE::Command/;

sub new{
    my ($class) = shift ;
    
    my $self = $class->SUPER::new(@_);
    bless $self, $class ;
    return $self ;
}




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


sub _killHandler{
    my ($self) = @_;
    print "ARGGGG I DIED\n";
 
    #close STDOUT ;
    #close STDERR ;
}


1;
