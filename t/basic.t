
use strict;
use warnings;
use Test::Simple tests => 1;        # Core
use File::Spec::Functions;          # Core
use File::Temp qw( tempdir );       # Core
use File::Copy::Recursive qw( dircopy );

###############################
#
# Test setup
#
#
###############################


use ETM;


my $tempdir = tempdir( CLEANUP => 1 )
    or die "Test setup failed: unable to create temp dir";
$ETM::etc = catfile( $tempdir, 'etc' );
$ETM::repo  = catfile( $tempdir, 'repo' );
$ETM::roots = catfile( $tempdir, 'roots' );

dircopy catfile('t', 'data', 'basic', 'etc'), $ETM::etc
    or die "Test setup failed: unable to copy test data into test dir";



