
use strict;
use warnings;
use Test::Simple tests => 5;        # Core
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

my $CLEANUP = (defined $ENV{ETM_TEST_CLEANUP} ? 0 : 1);
my $tempdir = tempdir( 'etm-test-dir-XXXXXXXXXX',
		       TMPDIR => 1 # , CLEANUP => $CLEANUP
    )
    or die "Test setup failed: unable to create temp dir";
$ETM::etc = catfile( $tempdir, 'etc' );
$ETM::repo  = catfile( $tempdir, 'repo' );
$ETM::roots = catfile( $tempdir, 'roots' );

dircopy catfile('t', 'data', 'basic', 'etc'), $ETM::etc
    or die "Test setup failed: unable to copy test data into test dir";


###############################
#
# Validate setup
#
#
###############################


ok( -d $ETM::etc );

###############################
#
# Validate initialization
#
#
###############################


ETM::init;


ok( -l $ETM::etc );
ok( -d $ETM::repo );

opendir REPO, $ETM::repo;
my @transactions = grep { ! /^\.\.?$/ } readdir REPO;
closedir REPO;

# The initial import and the "current" transaction
ok( scalar(@transactions) == 2);



ok( -d $ETM::roots );
