#!/usr/bin/env perl

use Liaison::EmailReplyManagement::StripEmail qw/strip_email/;
use File::Slurp;

die "usage: $0 <email file>\n" unless @ARGV;

$f = read_file($ARGV[0]);
$n = strip_email($f);

s/\n/\n\t/g foreach ($f, $n);

print "ORIGINAL EMAIL:\n\t$f\n";
print "STRIPPED EMAIL:\n\t$n\n";

