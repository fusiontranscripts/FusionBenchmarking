#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../PerlLib");
use DelimParser;

my $usage = "usage: $0 pred_results.scored  progA  progB\n\n";

my $scored_preds_file = $ARGV[0] or die $usage;
my $progA = $ARGV[1] or die $usage;
my $progB = $ARGV[2] or die $usage;



main: {

    my %TP_preds;
    my %FP_preds;
    
    open(my $fh, $scored_preds_file) or die $!;
    
    my $delim_parser = new DelimParser::Reader($fh, "\t");

    while (my $row = $delim_parser->get_row()) {

        my $prog = $row->{prog};
        if ($prog eq "$progA" || $prog eq "$progB") {
         
            my $J = $row->{J};
            my $S = $row->{S};
            
            my $pred_result = $row->{pred_result};
            if ($pred_result eq "TP") {
                my $selected_fusion = $row->{selected_fusion};
                $TP_preds{$selected_fusion}->{$prog} = "($J,$S)";
            }
            elsif ($pred_result eq "FP") {
                my $fusion = $row->{fusion};
                $FP_preds{$fusion}->{$prog} = "($J,$S)";
            }
        }

    }

    print "#pred_result\tfusion\t$progA\t$progB\n";
    foreach my $fusion (keys %TP_preds) {
        my $progA_results = $TP_preds{$fusion}->{$progA} || ".";
        my $progB_results = $TP_preds{$fusion}->{$progB} || ".";

        print join("\t", "TP", $fusion, $progA_results, $progB_results) . "\n";
    }

    print "#pred_result\tfusion\t$progA\t$progB\n";
    foreach my $fusion (keys %FP_preds) {
        my $progA_results = $FP_preds{$fusion}->{$progA} || ".";
        my $progB_results = $FP_preds{$fusion}->{$progB} || ".";
        
        print join("\t", "FP", $fusion, $progA_results, $progB_results) . "\n";
    }


    exit(0);
}



