package AEAE::Service ;

=head1 NAME

AEAE::Service - Exposes all service availables for managing an AEAE::Command

=head1 AUTHOR

jerome@eteve.net

=head1 DEPENDS

This module requires Data::UUID, Carp 


=head1 SYNOPSIS

my $ticket = AEAE::Service->launchCommand('AEAE::Command', 'param1', 'param2');

print "\nTicket : ".$ticket."\n";


while(1){
    sleep(1);
    my $r =  AEAE::Service->checkTicket($ticket);
    
    print "Check : ".$r."\n";
    
    if( $r  >= 100 ){ last ; }
}



my $std = AEAE::Service->getSTDOUT($ticket);

print "STDOUT: ".$std;


AEAE::Service->cleanTicket($ticket);



=head1 METHODS


=cut

use Carp ;
use POSIX qw(setsid);


=head2 launchCommand

Launch the given command and return a ticket.

Usage:

    my $cmd = 'AEAE::Command' ; # or any subclass of this.
    my $ticket = AEAE::Service->launchCommand($cmd, $arg1 , $arg2 ...);

$arg1, $arg2 ... are given to the command as arguments.

=cut

sub launchCommand{
    my ($class, $cmdClass , @cmdArgs ) = @_ ;
    
    eval "require $cmdClass" ;
    if( $@ ){
	#confess("Cannot load command $cmdClass: $@");
	# Never make mistakes (normally).
	return $class->launchCommand('AEAE::CommandErroneous',"Cannot load $cmdClass:". $@);
    }
    
    
    
    require Data::UUID;
    
    my $ug = new Data::UUID ;
    $uid = $sessId = $ug->create_str() ;
    
    if( $pid = fork() ){
	
	#print STDERR "In father . Returning ticket\n";
	return $cmdClass."/".$uid ;
	
    }
    else{
	#print STDERR "In son. Doing actual command\n";
	setsid();
	close STDIN ;
	close STDERR;
	close STDOUT;
	my $cmd = $cmdClass->new($uid);
	$cmd->doIt(@cmdArgs);
	exit(0);
    }
    
    
}


=head2 checkTicket

Given a ticket, return the pc of advancement of the corresponding command.

If pc >= 100, that means the command is over !

Usage:

    my $ticket = ... ; # A valid ticket
    my $pc = AEAE::Service->checkTicket($ticket);

=cut

sub checkTicket{
    #return "toto";
    my ($pack, $ticket)  = @_ ;
    my ($class,$pid) = split "/" , $ticket ;
    #return $class ;
    
    #confess("Class: ".$class." Id: ".$id);
    eval "require $class" ;
    if( $@ ){
	confess( "Cannot load class $class : $@");
    }
    
    my $cmd = $class->new($pid);
    
    #return $cmd ;
    return $cmd->checkStep();
}


=head2 getSTDOUT

Returns the STDOUT of the command. Wait the command to end to have the real STDOUT :)

Usage:
    my $ticket = ... ;
    my $stdout = AEAE::Service->getSTDOUT($ticket);


=cut

sub getSTDOUT{
    my ($pack, $ticket)  = @_ ;
    my ($class,$pid) = split "/" , $ticket ;
    #return $class ;
    
    #confess("Class: ".$class." Id: ".$id);
    eval "require $class" ;
    if( $@ ){
	confess( "Cannot load class $class : $@");
    }
    
    my $cmd = $class->new($pid);
    
    return $cmd->getSTDOUT();
    
}


=head2 getSTDERR

Same as getSTDOUT but for STDERR :)


=cut

sub getSTDERR{
    my ($pack, $ticket)  = @_ ;
    my ($class,$pid) = split "/" , $ticket ;
    #return $class ;
    
    #confess("Class: ".$class." Id: ".$id);
    eval "require $class" ;
    if( $@ ){
	confess( "Cannot load class $class : $@");
    }
    
    my $cmd = $class->new($pid);
    
    return $cmd->getSTDERR();
    
}

=head2 getError

If an error occured in the execution of the command, returns the error string.
Else return an empty string.

=cut

sub getError{
    my ($pack, $ticket) = @_ ;
    my ($class,$pid) = split "/" , $ticket ;
    #return $class ;
    
    #confess("Class: ".$class." Id: ".$id);
    eval "require $class" ;
    if( $@ ){
	confess( "Cannot load class $class : $@");
    }
    
    my $cmd = $class->new($pid);
    return $cmd->getError()  ;
}

=head2 getErrorMessage

Gets only the message associated with the error (without the call stack).
Returns empty string if no error occured.

=cut

sub getErrorMessage{
    my ($pack , $ticket) = @_;
    my ($class,$pid) = split "/" , $ticket ;
    
    eval "require $class" ;
    if( $@ ){
	confess( "Cannot load class $class : $@");
    }
    
    my $cmd = $class->new($pid);
    my $error =   $cmd->getError() ;
    
    return ( $error || '' ) ;
}



=head2 killTicket

Abort the command corresponding to the ticket.

Usage : 

    my $ticket = ... ;
    AEAE::Service->killTicket($ticket);

Returns: the STDOUT of the killed command.

=cut

sub killTicket{
    my ($self, $ticket)  = @_ ;
    my ($class,$pid) = split "/" , $ticket ;
    
    eval "require $class" ;
    if( $@ ){
	confess( "Cannot load class $class : $@");
    }
    
    my $cmd = $class->new($pid);
    
    my $res= $cmd->suicide() ;
    return $res;
 
}


=head2 cleanTicket

Clean the ressources associated with the ticket. Use it before throwing ticket to rubbish
to avoid ressource starvation.

    my $ticket = ... ; # A valid ticket
    AEAE::Service->cleanTicket($ticket);
    $ticket = undef ; # Ticket is not valid anymore.
 

=cut

sub cleanTicket{
    my ($self, $ticket ) = @_ ;
        my ($class,$pid) = split "/" , $ticket ;

    eval "require $class" ;
    if( $@ ){
	confess( "Cannot load class $class : $@");
    }
    
    my $cmd = $class->new($pid);
    return $cmd->clean();
}



1;
