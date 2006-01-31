#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'AEAE' );
}

diag( "Testing AEAE $AEAE::VERSION, Perl $], $^X" );
