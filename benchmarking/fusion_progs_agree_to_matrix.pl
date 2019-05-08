#!/usr/bin/env perl

use strict;
use warnings;

my $usage = "usage: $0 fusions.byProgAgree [min_progs=3]\n\n";

my $progs_agree_file = $ARGV[0] or die $usage;
my $min_progs_agree = $ARGV[1] || 3;

main: {

    my %prognames;
    my %fusion_preds;

    open(my $fh, $progs_agree_file) or die $!;
    while(<$fh>) {
        chomp;
        my @x = split(/\t/);
        my $fusion_name = $x[0];
        my $prog_list = $x[1];
        my $count_fusions = $x[2];

        if ($count_fusions < $min_progs_agree) {
            next;
        }
        
        my @progs = split(/,/, $prog_list);
        foreach my $prog (@progs) {

            $prognames{$prog} = 1;
            
            $fusion_preds{$fusion_name}->{$prog} = 1;
        }
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





