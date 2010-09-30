#!/usr/bin/env perl

use strict;
use warnings;

use lib '../lib';
use Email::StripEmail;
use File::Slurp;

die "usage: $0 <test email file>\n" unless @ARGV;

my $all = read_file($ARGV[0]);
my ($email, $expected) = $all =~ /^(.+)###EXPECTEDRESULT###(.+)$/s;
my $result = strip_email($email);

s/\n/\n\t/g foreach ($email, $result);

print "ORIGINAL EMAIL:\n\t$email\n";
print "STRIPPED EMAIL:\n\t$result\n";
