#!/usr/bin/env perl

## Note: There are no tests in this file, they are all stored in individual
##   files in the test_* directories. If you want to add a new test, put it
##   in a file.
##
## How to add new tests:
##  - Throw your new test into one of the test_* directories
##      - Use test_live for real life examples
##      - Use test_samples for contrived examples
##  - If neither of those folder categories works, you can create a new folder,
##    just make sure the name begins with test_ and it'll be picked up for 
##    testing automatically
##  - Every individual test file has three parts
##
##       1) the original email
##       2) the line ###EXPECTEDRESULT###
##       3) what we expect the email to look like
##     
##     This script will run strip_email against the original email, and
##     compare it to the expected result. Be sure to give it a good name.

use strict;
use warnings;

use Test::More;

use lib '../lib';
use Email::StripEmail;
use File::Slurp;
use Class::Struct;
use Data::Dumper;

## an individual test
struct ( TestEmail => [
    title           => '$',
    email           => '$',
    expected_result => '$',
]);

## run through each "test_*" directory
foreach my $test_dir (<test_*>) {
    next unless -d $test_dir;
    my $tests = get_test_emails_from_dir($test_dir);
    run_tests($tests);
}

exit;


## given a directory, look in it for test emails, and build an array of TestEmails
sub get_test_emails_from_dir
{
    my ($dir) = @_;
    
    my ($name_tag) = $dir =~ /^test_(.+)$/; ## a nice looking category
    
    my @tests;
    
    foreach my $file (<$dir/*>) {
#next unless $file =~ /quoting_marks-/;
        my $all = read_file($file);
        my ($email, $result) = $all =~ /^(.+)###EXPECTEDRESULT###(.+)$/s;
        
        if (!$email or !$result) {
            print STDERR "error on $file, cannot find email\n";
            print STDERR "error on $file, cannot find expected result\n";
            print $all;
            next;
        }
        
        foreach ($result) { s/^\s+//s; s/\s+$//s; }

        my $t = TestEmail->new(
            title           => "$name_tag - $file",
            email           => $email,
            expected_result => $result,
        );
        #print Dumper $t;
        push @tests, $t
    }
    
    return \@tests;
}

## given an arrayref of TestEmails, go through each one, strip it, and compare it
sub run_tests
{
    my ($tests) = @_;
    foreach my $test (@$tests) {
        my $result = strip_email($test->email);
        foreach ($result) { s/^\s+//s; s/\s+$//s; }
        is ($result, $test->expected_result, $test->title);
    }
}


