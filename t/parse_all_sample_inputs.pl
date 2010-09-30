#!/usr/bin/env perl

use strict;
use warnings;

my @emails;

$ARGV[0] and -r $ARGV[0] or die "big file argument required\n";
$ARGV[1] and -d $ARGV[1] or die "directory to store emails argument required\n";

open (my $FH, '<', $ARGV[0]) or die "cannot open $ARGV[0]";

our $type;
our $email;
our $typecount;

while (<$FH>) {
    if (/^\[ (.+) \]$/) { ## new section
        make_email();
        $type = $1;
        $type =~ s/\W/_/g;
        $email = '';
        $typecount = 0;
    } elsif (/^\s+(.*)$/)  { ## part of an email
        $email .= "$1\n";
    } elsif (/^\)/) { ## new email
        make_email();
        $email = '';
        $typecount++;
    } else { ## empty line, probably part of an email
        $email .= "\n";
    }
}

close $FH;

sub make_email
{
    if ($email =~ /\w/) {
        $email =~ s/^\n+//s;
        $email =~ s/\n+$//s;

        open (my $FH_OUT, '>', "$ARGV[1]/$type-$typecount") or die "cannot open $type-$typecount: $!";

        print $FH_OUT "$email\n";
        print $FH_OUT "###EXPECTEDRESULT###\n";
        print $FH_OUT "$email\n"; ## modify by hand

        close $FH_OUT or die "cannot close $type-$typecount: $!";
        print "created $ARGV[1]/$type-$typecount\n";
    }
}

