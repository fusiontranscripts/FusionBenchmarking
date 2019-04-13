#!/usr/bin/env perl

use strict;
use warnings;

my $usage = "usage: $0 preds.collected.scored\n\n";

my $preds_file = $ARGV[0] or die $usage;


main: {

    my %prog_to_sample_to_TP;
    my %samples;
    
    open(my $fh, $preds_file) or die $!;
    while(<$fh>) {
        if (/^\#/) { next; }
        chomp;
        my @x = split(/\t/);
      
        my $score_type = $x[0];
        my $prog = $x[1];
        my $sample_name = $x[2]; 
        my $fusion = $x[3];

        if ($score_type eq 'TP') {
            $prog_to_sample_to_TP{$prog}->{$sample_name}->{$fusion}++;
        }

        $samples{$sample_name}++;
        

    }
    close $fh;


    ## output matrix
    my @prognames = sort keys %prog_to_sample_to_TP;
    my @samplenames = keys %samples;
    
    print "\t" . join("\t", @prognames) . "\n";

    foreach my $sample (@samplenames) {
        my @vals = ($sample);
        foreach my $prog (@prognames) {
            my @TP_fusions;
            if (exists $prog_to_sample_to_TP{$prog}->{$sample}) {
                @TP_fusions = keys %{$prog_to_sample_to_TP{$prog}->{$sample}};
            }
            my $num_TP = scalar(@TP_fusions);
            push (@vals, $num_TP);
        }
        print join("\t", @vals) . "\n";
    }

    exit(0);
}





