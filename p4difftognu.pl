#!/usr/bin/perl -w

# Converts data from "p4 diff -du" or "p4 describe -du", on stdin, to real
#  unified diffs that GNU diff(1) might produce, on stdout. Specifically, to
#  data that GNU patch(1) might accept.
#
# Usage looks like:  p4difftognu.pl <myPerforceDiff.diff |patch -p1

use warnings;
use strict;

my $skipline = 0;

while (<STDIN>) {
    my $line = undef;
    $skipline = 0, next if $skipline;
    print($_), next if not (/\A==== (.*?) ====/);
    my $fname = $1;

    $skipline = 1;  # get rid of the extra blank line p4 inserts after.
    $fname =~ s#\A//##;
    $fname =~ s#\s*\(.*?\)\Z##;
    $fname =~ s/\#\d+\Z//;

    # This date is bogus, it's just what my test file happened to spit out.
    print("--- orig-$fname	2015-03-09 01:23:24.000000000 -0400\n");
    print("+++ $fname	2015-03-09 01:23:24.000000000 -0400\n");
}

