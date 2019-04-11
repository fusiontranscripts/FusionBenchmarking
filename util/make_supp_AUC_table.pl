#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;

my $usage = "usage: $0 search_dir token \n\n";

my $search_dir = $ARGV[0] or die $usage;
my $token = $ARGV[1] or die $usage;

my $cmd = "find $search_dir -regex \".\*fusion_preds.txt.scored.PR.AUC\" ";

my @files = `$cmd`;
chomp @files;

print join("\t", "read_set", "data_set", "progname", "AUC") . "\n";

foreach my $file (@files) {

    print STDERR "-processing $file\n";
    open (my $fh, $file) or die "Error, cannot open file: $file";

    my $data_set_name = basename(dirname($file));
    
    
    while (<$fh>) {
        print join("\t", $token, $data_set_name, $_);
    }

    close $fh;
    
}

exit(0);

