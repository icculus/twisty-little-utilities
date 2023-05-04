#!/usr/bin/perl -w

use warnings;
use strict;

sub usage {
    die("USAGE: $0 <srcpath> <dstpath>\n");
}


my $srcpath = undef;
my $dstpath = undef;

foreach (@ARGV) {
    $srcpath = $_, next if not defined $srcpath;
    $dstpath = $_, next if not defined $dstpath;
    usage();
}

usage() if not defined $srcpath;
usage() if not defined $dstpath;

opendir(my $dirp, $srcpath) or die("Couldn't opendir '$srcpath': $!\n");
while (readdir($dirp)) {
    my $fname = $_;
    my $fullpath = "$srcpath/$fname";
    next if not -f $fullpath;
    if (/\A(\d\d\d\d)\-(\d\d)\-(\d\d) \d\d\.\d\d\.\d\d/) {
        my $year = $1;
        my $month = $2;
        my $day = $3;
        mkdir("$dstpath");
        mkdir("$dstpath/$year");
        mkdir("$dstpath/$year/$month");
        my $fulldstpath = "$dstpath/$year/$month/$fname";
        die("uhoh, '$fulldstpath' already exists!\n") if ( -f $fulldstpath );
        #print("mv '$fullpath' '$fulldstpath'\n");
        system("mv '$fullpath' '$fulldstpath'");
        if ($? == -1) {
            die("failed to execute 'mv': $!\n");
        } elsif ($? & 127) {
            my $sig = ($? & 127);
            die("'mv' died with signal $sig\n");
        } else {
            my $rc = ($? >> 8);
            if ($rc != 0) {
                die("'mv' failed with exit code $rc\n");
            }
        }
    }
}
closedir($dirp);

exit(0);
