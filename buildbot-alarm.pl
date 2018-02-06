#!/usr/bin/perl -w

use warnings;
use strict;
use LWP::Simple;
use JSON;

sub usage {
    print STDERR "USAGE: $0 <baseurl> <handler> <runEveryXSeconds>\n";
    exit(1);
}

my $baseurl = undef;
my $handler = undef;
my $loopdelay = undef;

foreach (@ARGV) {
    $baseurl = $_, next if not defined $baseurl;
    $handler = $_, next if not defined $handler;
    $loopdelay = int($_), next if not defined $loopdelay;
    usage();  # too many arguments.
}

usage() if (not defined $baseurl);
usage() if (not defined $handler);
$loopdelay = 0 if (not defined $loopdelay);

# Trim off any trailing '/' char.
$baseurl =~ s#/+\Z##;

my $failstate = -1;
while (1) {
    my $failed = 0;
    my $inprogress = 0;

    my $jsontext = get("$baseurl/json/builders/");
    die "Couldn't get list of builders!\n" if (not defined $jsontext);
    my $json = decode_json($jsontext);

    my @builders = ();
    my %builderstate = ();
    if (not defined $json) {
        print STDERR "Couldn't get list of builders!\n";
        $failed = 1;
    } else {
        foreach my $builder (sort keys(%$json)) {
            push @builders, $builder;
            if (defined($json->{$builder}->{'state'})) {
                $builderstate{$builder} = $json->{$builder}->{'state'};
            }
        }
    }
    $json = undef;

    foreach my $builder (@builders) {
        my $builderstate = $builderstate{$builder};
        my $offline = (defined $builderstate && $builderstate eq 'offline');
        my $url = "$baseurl/json/builders/$builder/builds/-1";
        $jsontext = get($url);
        if (not defined $jsontext) {
            print STDERR "Failed to download '$url'\n";
            $failed = 1;
            next;
        }

        $json = decode_json($jsontext);
        $jsontext = undef;
        if (not defined $json) {
            print STDERR "Invalid JSON data from '$url'\n";
            $failed = 1;
            next;
        }
        my $buildnum = $json->{'number'};
        my $results = defined $json->{'results'} ? int($json->{'results'}) : 0;
        my $thisinprogress = 1 if (defined $json->{'currentStep'});
        $json = undef;

        $inprogress = 1 if ($thisinprogress);

        my $resultstr;
        if ($offline) {
            $resultstr = "OFFLINE";
            $failed = 1;
        } elsif ($thisinprogress) {
            $resultstr = "IN PROGRESS";
        } elsif ($results == 0) {
            $resultstr = "SUCCESS";
        } else {
            $resultstr = 'FAILURE';
            $failed = 1;
        }

        print("$builder: build #$buildnum $resultstr\n");
    }

    print("\n");

    print("\nfailure state: $failed (previously $failstate)\n\n");
    if ($failed != $failstate) {
        # only report if there was a definite failure or we're
        #  not running a build right now.
        if ($failed || !$inprogress) {
            my @args = ( $handler, "$failed" );
            (system(@args) == 0) or die("Launching '$handler' failed: $?\n");
            $failstate = $failed;  # only alert when status has changed (or on startup).
            print("\n");
        }
    }

    last if ($loopdelay == 0);
    print("Sleeping $loopdelay seconds...\n");
    sleep($loopdelay);
}

exit(0);

# end of buildbot-alarm.pl ...

