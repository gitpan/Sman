# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use strict;
use warnings;
use Test;
use Config;

BEGIN { plan tests => 2 };
my $perlpath = $Config::Config{perlpath}; 
my @lines;

eval { @lines = `$perlpath script/sman -h`; };
ok( ($@) ? (0) : 1);

eval { @lines = `$perlpath script/sman-update -h`; };
ok( ($@) ? (0) : 1);

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

