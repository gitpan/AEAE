package AEAE::AsyncCGIPage ;

use base qw/Class::AutoAccess/ ;
use CGI::Ajax ;
use AEAE::Service ;

=head2 new

$cgi Must be a CGI object (version 3.15 is tested)
$nbArgs Must be a valid positive integer . Represent the number of arguments the generated page will be able to handle
for the command.

Usage:
    my $page = AEAE::AsyncCGIPage($cgi , $nbArgs );

Properties you can set:
    
    $page->command('Command') ;

The class that implements the command to execute. This class must inherit from AEAE::Command (see this module for more info).

    $page->arguments(['arg1','arg2']) ;

A reference on a array of the arguments to give to the command. These
arguments have to be strictly strings (or number).

    $page->debug(0|1);

Switch on/off debug mode. In debug mode, you see ajax calls at the bottom of
the page.

    $page->autoStart(0|1);

If 1 , tells the page to automatically start the command, without waiting for the user to click
on the start button.

    $page->onAbortURL('http://.....');

Redirect there when user push the abort button. If not set, it just make a back.

    $page->onCompleteURL('http://.....');

Redirect there when the command is complete and throw no errors.

    $page->checkInterval(5000);

In ms, the time between two refresh of the progress bar.
Dont go below 3000 since we experiments some problems with IE with a short interval.

    $page->message('doing wonderfull command');

Sets the message to show to the user while the command is executing.
The default is ok at devellopment time !

    $page->headCode('<meta ....');

Anything you want to insert in the head part of the generated html. Please take care being html compliant.
You may break the component if not.

    $page->beforeComponentHTML('<.....>');

Anything you want to insert before the component. Same notice as before.

    $page->afterComponentHTML('<...>');
Anything you want to insert after the component. Same notice as before.

    $page->barBgColor('#TOTOTO');
The color used in the background of the progress bar

    $page->barFgColor('#TOTOTO');
The color used in the foreground of the progress bar

=cut

sub new{
    my ($class, $cgi, $nbArgs ) = @_ ;
    
    my $self = {
	'cgi' => $cgi ,
	'nbArgs' => $nbArgs ,
	'arguments' => ['No argument given'],
	'command' => 'AEAE::CommandErroneous',
	'debug' => 0 ,
	'autoStart' => 0 ,
	'onAbortURL' => '' ,
	'onCompleteURL' => '',
	'checkInterval' => 5000 ,
	'message' => undef,
	'headCode' => '' ,
	'beforeComponentHTML' => '' ,
	'afterComponentHTML' => '',
	'barBgColor' => '#336699',
        'barFgColor' => '#99ccff'
	};
    
    return bless $self, $class ;
}


=head2 getMessage

Return the setted message or a default message build on command and arguments given.

=cut

sub getMessage{
    my ($self) = @_ ;
    if( ! $self->message()){
	return 'Executing command : '.$self->command().' with args: '.join(',',@{$self->arguments()}); 
    }
    return $self->message();
}


    

my $sayHello = sub {
    my ($who) = @_ ;
    return "Hello ".$who."\n";
};

my $launchCommand = sub {
    my ($cmd, @args ) = @_ ;
    return  AEAE::Service->launchCommand($cmd,@args);
};

my  $checkTicket= sub{
    my ($ticket) = @_ ;
    return AEAE::Service->checkTicket($ticket);
};

my $getSTDOUT = sub {
    my ($ticket) = @_ ;
    return AEAE::Service->getSTDOUT($ticket);
};

my  $getSTDERR = sub {
    my ($ticket) = @_ ;
    return AEAE::Service->getSTDERR($ticket);
};

my  $getError =  sub {
    my ($ticket) = @_ ;
    return AEAE::Service->getError($ticket);
};

my  $cleanTicket =  sub {
    my ($ticket) = @_ ;
    return AEAE::Service->cleanTicket($ticket);
};

my  $killTicket = sub{
    my ($ticket) = @_ ;
    
    return AEAE::Service->killTicket($ticket);
};



=head2 generateAjaxedHTML

Return a string to be sent at the client. It is ajaxed HTML with CGI::Ajax !

=cut

sub generateAjaxedHTML{
    my ($self) = @_ ;

    
    my $genHtml = q^
	<html>
	<head>
	<style type="text/css">

	.progress{
	    background-color: ^.$self->barFgColor().q^;
	    width: 1px;
	    height: 14px;
	    text-align: center;
	    font-size: 10pt;
	    font-family: Verdana, Arial, Helvetica, sans-serif, "Lucida Sans";
	    color: #336699;
	}

	.tour{
	    background-color: ^.$self->barBgColor().q^;	  
	    
	    width: 106px;
	   
 	 }
    </style>^.
	$self->headCode().
	q^ 
	
	</head>
	<body>
	^.
	$self->beforeComponentHTML().q^
		
	<script language="JavaScript">
	var tid ;
        var stateCommand = 'normal' ;
	var onAbortURL = '^.$self->onAbortURL().q^' ;
	var onCompleteURL = '^.$self->onCompleteURL().q^' ;
    
     function afterlaunch(){
	//alert('In afterlaunch');
	var ticket = arguments[0];
	var tickContent = document.getElementById('ticket') ;
	tickContent.value = ticket ;
	
	//document.getElementById('status').value='0';
	document.getElementById('stdout').value='';
	document.getElementById('stderr').value='';
	document.getElementById('error').value='' ;
	setStatus(0);
	//checkTicket(['ticket','NO_CACHE'], [afterCheck]);
	//alert("Setting timer interval");
	tid = setInterval("checkTicket(['ticket', 'NO_CACHE'] , [afterCheck])" , ^.$self->checkInterval().q^);
    }
    
    function afterclean(){
	document.getElementById('ticket').value='';
	//alert('In afterClean with stateCommand =' + stateCommand );
	
	doFinish();
	
	//stateCommand = 'normal' ;
	//document.getElementById('status').value='';
	//document.getElementById('stdout').value='';
	//document.getElementById('stderr').value='';
	//document.getElementById('error').value='' ;
	
    }
    
    
    function setStatus(status){
	//var status = arguments[0];
	var stat = document.getElementById('status') ;
	stat.value=status ;
	
	document.getElementById('bar').style.width=status ;
	document.getElementById('bar').innerHTML=status+"%";
    }
    
    function afterCheck(){
	var status = arguments[0];	
	
	setStatus(status);

	//alert("In after check");
	
	document.getElementById('getSTDERRBut').click();
	document.getElementById('getSTDOUTBut').click();
	
	getError(['ticket','NO_CACHE'],[afterError]);
		
	if( status >= 100  ){
	    clearInterval(tid);
	    document.getElementById('cleanBut').click();
	}
    }
    
    function doFinish(){

        //alert('Command completed');  	
	document.getElementById('abortBut').disabled='true' ;
	
	//alert('In do finish with stateCommand =' + stateCommand );
       if (  stateCommand == 'aborted' ){
 	    alert('You cancelled this command');
	    if( onAbortURL !== ''){
		window.location.href = onAbortURL ;
	    }
	    else{
		history.back();
	    }
 	    return ;
 	}
	
	if( stateCommand == 'error' ){
	    alert('Error:' + document.getElementById('error').value.substring(0,100) + '...'  + '\n' +
		  'Send Error content to support and click back to resume normal operation');
 	    return ;
 	}
 	if ( stateCommand == 'normal' ){
 	  alert('Command ended successfully . Going to ' + onCompleteURL);
	  window.location.href = onCompleteURL ;
 	}
    }

    function afterError(){
	var errorV = arguments[0];
	if( errorV !== '' ){
	    stateCommand = 'error' ;
	    var err = document.getElementById('error');
	    err.value = errorV ;
	    switchLogs('show');
	    //document.getElementById('logs').style.visibility='visible';
	    //document.getElementById('stdout').style.visibility='visible';
	    //document.getElementById('error').style.visibility='visible';
	    //alert('An error occured:'+errorV.substring(0,100) + '...');
	    //document.getElementById('cleanBut').click();
	 
	}else{
	    //stateCommand = 'normal' ;
	}
    }

    function afterAbort(){
	stateCommand = 'aborted' ;
	document.getElementById('logs').style.visibility='visible';
	afterCheck(100);
    }
    
    
    function switchLogs(force){
	var log = document.getElementById('logs');
	if( force == 'show' || log.style.visibility == 'hidden'  ){
	    log.style.visibility = 'visible';
	    log.style.display = 'block' ;
	}
	else{
	    log.style.visibility = 'hidden';
	    log.style.display = 'none' ; 
	}
    }
    
    
    </script>
	
	<input type="hidden" name="asynCommand" id="asynCommand" value="^.$self->command().q^">^;
      
    my $i = 0 ;
    my $jscriptLaunch = "launchCommand(['asynCommand',";
    
    foreach my $arg ( @{$self->arguments()}){
	$genHtml .= '<input type="hidden" name="asynArg'.$i.'" id="asynArg'.$i.'" value="'.$arg.'">';
	$jscriptLaunch .= "'asynArg$i'," ;
	$i++ ;
    }
    $jscriptLaunch .= "'NO_CACHE'],[afterlaunch]);";
    
    $genHtml .= qq^
	<input type="hidden"  id="ticket"></input>
	 <input type="button" value="check" id="checkButton" onclick="checkTicket(['ticket', 'NO_CACHE'] , [afterCheck]);" style="visibility:hidden;display:none">
     
	 <input type="hidden" name="status" id="status">
	 
<!-- 	 <table width="100" border="1"> -->
<!-- 	 <tr> -->
<!--          <td id="bar" width="1" bgcolor="red" ></td><td></td> -->
<!-- 	 </tr> -->
<!-- 	 </table> -->
	 <br/>
	 <br/>
	 <center>
	 <br/>
	 ^.$self->getMessage().qq^
	 <br/>
	 <br/>
	 <table class="tour"><tr><td><div id="bar" class="progress"></div></td></tr></table>
	 <br/>
	 <input type="button" value="[ Start ]" name="launch" id="launchBut" onclick="this.disabled='true';$jscriptLaunch">
	 <input type="button" value="Abort" id="abortBut" onclick="killTicket(['ticket','NO_CACHE'],[afterAbort]);" ><br/>
	 <a href="#" onclick='switchLogs();'>&nbsp;</a>

	 </center>
	 <br/>
	 <input type="button" value="getSTDOUT" id="getSTDOUTBut" onclick="getSTDOUT(['ticket' ,'NO_CACHE'] , ['stdout']);" style="visibility:hidden;display:none">
	 
	 <div id="logs"   style="visibility:hidden;display:none">
	Error:<br/>
	 <textarea name="error" rows="10" cols="50" id="error" ></textarea>
	 <br/>
        Standard out:<br/>
	 <textarea name="stdout" id="stdout" rows="10" cols="50"  ></textarea>
	 <br/>
        Standard error:<br/>
	 <textarea name="stderr" id="stderr" rows="10" cols="50" ></textarea>
	 </div>

	 <input type="button" value="getSTDERR" id="getSTDERRBut" onclick="getSTDERR(['ticket' , 'NO_CACHE'], ['stderr']);" style="visibility:hidden;display:none">

	 <input type="button" value="clean" id="cleanBut" onclick="cleanTicket(['ticket', 'NO_CACHE'] , [afterclean]);" style="visibility:hidden;display:none">
	^ ;
    if( $self->autoStart() ){
	$genHtml .= "<script language=\"javascript\">document.getElementById('launchBut').click();</script>\n";
    }
    
    $genHtml .= $self->afterComponentHTML();
    
    $genHtml .= q^
	 </body>
	 </html>
	 ^ ;
    
    my $ajax = new CGI::Ajax('sayHello' => $sayHello);
    $ajax->register('launchCommand' , $launchCommand );
    $ajax->register('checkTicket' , $checkTicket );
    $ajax->register('getSTDOUT' , $getSTDOUT );
    $ajax->register('cleanTicket' , $cleanTicket );
    $ajax->register('getSTDERR', $getSTDERR );
    $ajax->register('getError', $getError );
    $ajax->register('killTicket' , $killTicket);

    $ajax->JSDEBUG($self->debug());
    
    return $ajax->build_html($self->cgi() , $genHtml);
    
}






1;
