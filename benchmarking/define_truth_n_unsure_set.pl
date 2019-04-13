#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;

my $usage = "\n\n\tusage: $0 preds.collected.byProg min_truth\n\n";

my $preds_collected = $ARGV[0] or die $usage;
my $min_truth = $ARGV[1] or die $usage;

main: {
    
    open(my $fh, $preds_collected) or die "Error, cannot open file $preds_collected";

    my $out_basename = basename($preds_collected);
    
    open(my $ofh_truth, ">$out_basename.min_${min_truth}.truth_set") or die $!;
    open(my $ofh_unsure, ">$out_basename.min_${min_truth}.unsure_set") or die $!;
    
    while (<$fh>) {
        chomp;
        my ($fusion_name, $prog_list, $prog_count) = split(/\t/);
        if ($prog_count >= $min_truth) {
            print $ofh_truth "$fusion_name\n";
        }
        elsif ($prog_count > 1) {
            print $ofh_unsure "$fusion_name\n";
        }
    }

    close $fh;
    close $ofh_truth;
    close $ofh_unsure;

    exit(0);
}
