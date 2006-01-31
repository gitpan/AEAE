package AEAE::Command ;

=head1 NAME

AEAE::Command - a base class for an asynchroneous command.

=head1 AUTHOR

jerome.eteve@it-omics.com

=head1 SYNOPSIS

Use this class as a base class when you wand to implement an asynchroneous command usable by AEAE::Service.

You only have to inherit from this class and implement the methods _doItReal and (eventually) _killHandler .

See those methods for more details.

See AEAE::CommandExample for a simple example.

=head1 METHODS

=cut


use Carp;

my $workingDirectory = '/tmp/';

$AEAE::Command::processCommand = bless {} , 'AEAE::Command' ;

use base qw/Class::AutoAccess/;

=head2 new

Always override this method in subclasses in this way:

sub new{
    my ($class) = @_ ;
    
    my $self = $class->SUPER::new(@_);
    bless $self, $class ;
    return $self ;
}

YOU CANNOT DO ANOTHER WAY. Any attempt to make another constructor will fail.

=cut

sub new{
    my ($class, $id ) = @_ ;
    
    my $self = {
	'id' => $id ,
	'dir' => $workingDirectory.'AEAECommand_'.$id

	} ;
    
    bless $self, $class ;
    
    # Allowing resssources if not here.
    if( ! -d $self->dir()){
	mkdir $self->dir() , 0777  ;
	open F , '>'.$self->dir().'/'."pc" ;
	print F "0" ;
	close F ;
	#if( $! )
	#{ confess "Cannot make ".$self->dir().":".$!."\n"; }
    }
 
    $self->dir($self->dir()."/");
    
    $self->setError();
    $AEAE::Command::processCommand = $self ;
    return $self ;
}


=head2 runningpid

Get/Set the pid of the process running this command.

=cut

sub runningpid{
    my ($self, $v) = @_;
    if(defined  $v ){
	open F , ">".$self->dir()."pid";
	print F $v;
	close F;
	return $v ;
    }
    else{
	open F ,$self->dir()."pid";
	my $pid = <F>;
	close F ;
	return $pid ;
    }
    
}

=head2 getSTDOUT

Get the standard ouput content of this command.

Usage:

    my $stdout = $cmd->getSTDOUT();

=cut

sub getSTDOUT{
    my ($self) = @_ ;
    my $content = "Default content";
    eval
    {
	open F , $self->dir()."STDOUT" ;
	local $/ = undef ;
	$content = <F> ;
	close F ;
    };
    if( $@ ){
	confess("Cannot read STDOUT : $@");
    }
    return $content ;
}


=head2 getSTDERR

Same as getSTDOUT but for STDERR

=cut

sub getSTDERR{
    my ($self) = @_ ;
    my $content = "Default content";
    eval
    {
	open F , $self->dir()."STDERR" ;
	local $/ = undef ;
	$content = <F> ;
	close F ;
    };
    if( $@ ){
	confess("Cannot read STDERR : $@");
    }
    return $content ;
}

=head2 isLocked

Returns true if is locked, false otherwise.
Locked means that the process is not finished yet.

=cut

sub isLocked{
    my ($self) = @_ ;
    if ( -e $self->dir()."lock" ){
	return 1 ;
    }
    return 0 ;
}

=head2 isDone

Returns true when it is done.

=cut

sub isDone{
    my ($self) = @_ ;
    #confess (" Called on ".$self->id());
    if( -e $self->dir()."done"){
	return 1 ;
    }
    return 0 ;
    
}

=head2 done

Set to true the done status. Can be used once.

=cut

sub done{
    my ($self) = @_ ;
    
    if( $self->isDone() ){
	confess "$self Allready finished";
    }
    open F , '>'.$self->dir()."done" ;
    close F ;
}



sub lock{
    my ($self) = @_ ;
    if( $self->isLocked() ){
	confess "$self allready locked";
    }
    open F , '>'.$self->dir()."lock" ;
    close F ;
}

sub unlock{
    my ($self) = @_ ;
    if ( ! $self->isLocked() ){
	confess "$self allready unlocked";
    }
    unlink $self->dir()."lock" ;
}


sub isFake{
    my ($self) = @_ ;
    return ! $self->{'id'};
}

=head2 oneStep

Use this to specifie the percentage of advance of this process.

=cut

sub oneStep{
    my ($self, $pc) = @_ ;
    if( $self->isFake()){ return ;}
    open F, ">".$self->dir()."pc"  ;
    print F $pc ;
    close F ;
}


sub setError{
    my ($self, $error) = @_ ;
    
    open( F , ">>".$self->dir()."error" );
    if( $error ){ 
	#print STDERR "SETTING ERROR : $error\n";
	print F $error ;
    } 
    close F ;
    
}

sub getError{
    my ($self , $error ) = @_ ;
    #return "ARGGGGGGG";
    #print STDERR "Getting error\n";
    local $/ = undef ;
    open ( F , $self->dir()."error" ) || die "Cannot open error file" ;
    my $err = <F> ;
    close F ;
    
    #print STDERR "Error is : ".$err."\n";
    return $err;
}


sub checkStep{
    my ($self) = @_ ;
    open F  , $self->dir()."pc";
    my $pc = <F>;
    close F ;
    if ( $pc ){
	return $pc;
    }
    return 0 ;
}

=head2 suicide

Kill yourself !!

=cut

sub suicide{
    my ($self) = @_;
    my $pid = $self->runningpid();
    #return "KILLING $pid";
    kill INT, $self->runningpid();
    return $self->getSTDOUT();
}


sub doIt{
    my $self = shift ;
    
    if( $self->isLocked() || $self->isDone() ){
	confess "Cannot launch twice same command\n";
    }

    $self->lock();
 
    $SIG{INT} = sub { $self->_killHandler() ; $self->done() ; exit(0)};
    
    
    # Redirect STDOUT and STDERR in files.
    open STDOUT , ">".$self->dir()."STDOUT";
    open STDERR , ">".$self->dir()."STDERR";
    
    
    print "Setting pid : ".$$."\n";
    $self->runningpid($$);
    
    eval{
	$self->_doItReal(@_);
    };
    if( $@ ){
	print STDERR "ERROR : $@";
	$self->setError($@);
    }
    
    
    $self->unlock();
    $self->done();

    $self->oneStep(100);

    close STDERR ;
    close STDOUT ;
    
}



=head2 _doItReal

Overide this method in subclasses.
This is the main method executing the action to be made asynchroneous.

You must implement this method as a regular synchroneous procedure.
You cannot return anything.

Within this method, you can (and must) access the current command to indicate
the framework where you are in your procedure.
For instance, if you are at 50% done, call :

$AEAE::Command::processCommand->oneStep(50);


Example of implementation:
    
    sub _doItReal{
	my $self = shift ;
	my $arg1 = shift ;
	my $arg2 = shift ;
	# ...
	my $i = 0 ;
	
	print "Ca commence !\n";
	
	while( $i < 101){
	    
	    $AEAE::Command::processCommand->oneStep($i);
	    print "Step ".$i."\n";
	    $i += 1 ;
	    select(undef, undef, undef, 0.25);  
	}
	print "C'est fini !\n";
    }


=cut

sub _doItReal{
    my $self = shift ;
    confess("Method _doItRead not implemented in class ".ref($self));
#     my $i = 0 ;

#     print "Ca commence !\n";

#     while( $i < 101){
	
# 	$AEAE::Command::processCommand->oneStep($i);
# 	print "Step ".$i."\n";
# 	$i += 1 ;
# 	select(undef, undef, undef, 0.25);  
#     }
#     print "C'est fini !\n";
}



=head2 _killHandler

Called on myself when this command receive the order to suicide.
Implement here release of ressources, termination of other process etc..

This method is called in the same memory space of the launched command. That means it is the same
memory space as you are in the _doItReal method. Hence, any values setted in memory (for instance in $self->...)
within the _doItReal method will be available here also.


=cut

sub _killHandler{
    my ($self) = @_;
    print STDERR "AM DEAD\n";
    # Nothing by default.
}


sub clean{
    my ($self ) = @_ ;
    if( $self->isDone()){
	$cmd = "rm -rf ".$self->dir() ;
	system($cmd);
    }
}



1;
