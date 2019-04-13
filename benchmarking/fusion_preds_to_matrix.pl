#!/usr/bin/env perl

use strict;
use warnings;

my $usage = "usage: $0 preds.collected\n\n";

my $preds_file = $ARGV[0] or die $usage;


main: {

    my %prognames;
    my %fusion_preds;

    open(my $fh, $preds_file) or die $!;
    my $header = <$fh>;
    unless ($header =~ /^sample\tprog/) {
        die "Error, missing expected header format for $preds_file";
    }
    while(<$fh>) {
        chomp;
        my @x = split(/\t/);
        my $sample_name = $x[0];
        my $prog = $x[1];
        my $fusion_name = uc $x[2];
        my $J = $x[3];
        my $S = $x[4];

        my $sum_JS = $J + $S;

        $fusion_name = "$sample_name|$fusion_name";

        $prognames{$prog} = 1;
        
        $fusion_preds{$fusion_name}->{$prog} = $sum_JS;
        
    }
    close $fh;


    ## output matrix
    my @prognames = sort keys %prognames;
    my @fusions = sort keys %fusion_preds;

    print "\t" . join("\t", @prognames) . "\n";

    foreach my $fusion (@fusions) {
        my @vals = ($fusion);
        foreach my $progname (@prognames) {
            my $val = $fusion_preds{$fusion}->{$progname} || 0;
            push (@vals, $val);
        }
        
        print join("\t", @vals) . "\n";
    }

    exit(0);
}





