#!/usr/bin/env perl

use strict;
use warnings;

my $usage = "\n\n\tusage: $0 auc_list.files\n\n";

my $auc_files_filename = $ARGV[0] or die $usage;

main: {
    
    my @files = `cat $auc_files_filename`;
    chomp @files;

    print join("\t", "progname", "min_thresh", "ignoreUnsure", "okpara", "auc") . "\n";
    
    foreach my $file (@files) {

        $file =~ /min_(\d+)/ or die "Erorr, no min val extracted from $file";
        
        my $min_thresh = $1;

        my $ignoreUnsure = 0;
        if ($file =~ /ignoreUnsure/) {
            $ignoreUnsure = 1;
        }
        
        my $okpara = 0;
        if ($file =~ /okPara/) {
            $okpara = 1;
        }
        
        my @data = `cat $file`;
        chomp @data;
        
        foreach my $line (@data) {
            my ($progname, $auc) = split(/\t/, $line);
            print join("\t", $progname, $min_thresh, $ignoreUnsure, $okpara, $auc) . "\n";
        }
        
    }
    
    exit(0);
    
}
