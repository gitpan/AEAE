package AEAE;

use warnings;
use strict;

=head1 NAME

AEAE - the Ajax Enhanced Asynchroneous Experience.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

This module enables you to quickly implement long duration task at server side
while allowing the user to control those task at client side with an ajaxed page
showing a progress bar and control button.

=head1 SCREENSHOTS

http://jerome.eteve.free.fr/article.php3?id_article=26

=head1 COMPATIBILITY

This distribution is compatible (means tested and works) with:

At server side: POSIX capable system (linux tested), apache(2.x tested).

At client side: FF1.5 (tested), IE5 (tested), IE6 (tested).

No java, no flash, nothing but plain javascript.

=head1 USAGE

To use AEAE, you only got two things to write:

=head2 The actual server task to do.

For this just make a class that inherits from AEAE::Command,
and simply implement the _doIt() method.

See the AEAE::ComandExample :

(extract):

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

See AEAE::Command for full doc and AEAE::CommandExample for full example!

The importants things are:

- All you need to do is to implement your task just as if would be a regular one. Dont worry about synchroneous issues.

- All you write on STDOUT and STDERR will be visible to the final user, so dont be
too wordy.

- If you die or confess, the error message will be visible to the user, so be clear!

- You got to use the $AEAE::Command::processCommand->oneStep(<number>); to gives
information to the user on how much your task is complete. If number >= 100, your task will be considered as
complete (thus eliminated) by the system, so give number between 1 and 99 !


=head2 The CGI that generates the interface.

Once your command is written, you got to write the cgi that will generate your web interface.
For that, you will use the AEAE::AsyncCGIPage module.

Just a simple example:

     #! /usr/bin/perl -w

    use AEAE::AsyncCGIPage ;

    use strict ;

    use CGI ;

    my $c = new CGI ;

    my $page = AEAE::AsyncCGIPage->new($c,1);
    $page->command('AEAE::CommandExample');
    $page->arguments([0]);
    $page->debug(1);
    print $page->generateAjaxedHTML();


This CGI generates an ajaxed page that will control the AEAE::CommandExample and will give it the argument '0' .

The debug(1) makes ajax call appears in the page.

See AEAE::AsyncCGIPage for full documentation about all features.

=head1 DEPENDS

This distribution hardly depends on the wonderfull CGI::Ajax module.

=head1 AUTHOR

Jerome Eteve, C<< <jerome@eteve.net> >> Core dev.
Yannick Lesage, C<< <yan.lesage@free.fr> >> Design, testing and advices.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-aeae@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=AEAE>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Jerome Eteve, Yannick Lesage all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of AEAE
