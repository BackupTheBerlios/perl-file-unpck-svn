#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'File::Unpack' ) || print "Bail out!
";
}

diag( "Testing File::Unpack $File::Unpack::VERSION, Perl $], $^X" );
