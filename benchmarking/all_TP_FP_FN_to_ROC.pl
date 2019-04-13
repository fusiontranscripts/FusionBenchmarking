#!/usr/bin/env perl

use strict;
use warnings;


my $usage = "\n\n\tusage: $0 summary.TP_FP_FN\n\n";

my $tp_fp_fn_file = $ARGV[0] or die $usage;

main: {

    my %data = &parse_file($tp_fp_fn_file);    
    
    print join("\t", "prog", "min_sum_frags", "TP", "FP", "FN", "TPR", "PPV", "F1") . "\n";

    foreach my $prog (keys %data) {
        my $progdata_href = $data{$prog};
        
        &make_ROC($prog, $progdata_href);
    }
    
    exit(0);
}


####
sub make_ROC {
    my ($prog_name, $progdata_href) = @_;

    my %data = %$progdata_href;
    
    my @TP_fusions = ($data{TP}) ? @{$data{TP}} : ();
    my @FP_fusions = ($data{FP}) ? @{$data{FP}} : ();
    my @FN_fusions = ($data{FN}) ? @{$data{FN}} : ();
    
    my $num_truth_fusions = scalar(@TP_fusions) + scalar(@FN_fusions);
    my $num_total_FP = scalar(@FP_fusions);
    
    my @uniq_vals = sort {$a<=>$b} &get_unique(@TP_fusions, @FP_fusions);
    
    for (my $i = 0; $i < $#uniq_vals; $i++) {

        my $min_val = $uniq_vals[$i];
        
        @TP_fusions = grep { $_ >= $min_val } @TP_fusions;
        
        @FP_fusions = grep { $_ >= $min_val } @FP_fusions;

        my $num_TP = scalar(@TP_fusions);
        my $num_FP = scalar(@FP_fusions);
        my $num_FN = $num_truth_fusions - $num_TP;
        
        my $TPR = sprintf("%.2f", $num_TP / $num_truth_fusions); # True Positive Rate

        my $FDR = sprintf("%.2f", $num_FP / ($num_FP + $num_TP)); # False Discovery Rate
        
        my $PPV = 1 - $FDR; # Positive Predictive Value
        

        my $Sn = $TPR;   # using true positive rate as 'sensitivity' measure
        my $Sp = $PPV;   # using positive predictive value as 'specificity' measure
        
        
        my $F1 = "NA";
        eval {
            $F1 = sprintf("%.3f", 2 * $Sn * $Sp / ($Sn + $Sp) );
        };
        
        print join("\t", $prog_name, $min_val, $num_TP, $num_FP, $num_FN, $TPR, $PPV, $F1) . "\n";
    }
    
    return;
}


####
sub parse_file {
    my ($fusions_file) = @_;
    my %data;
    
    
    my %seen;
    
    open (my $fh, $fusions_file) or die $!;
    
    my $header = <$fh>;
    unless ($header =~ /^pred_result/) {
        die "Error, not reading expected header format for $fusions_file";
    }
    while (<$fh>) {
        chomp;
        my @x = split(/\t/);
        unless (scalar @x == 10) {
            die "Error, did not parse 10 fields from row: $_";
        }
        my ($pred_type, $sample_name, $progname, $fusion, $J, $S, 
            $mapped_gencode_A, $mapped_gencode_B, $explanation, $selected_fusion) = @x;
        
        unless ($pred_type =~ /^(TP|FP|FN)$/) { next; }
                
        if ($selected_fusion ne '.') {
            $fusion = $selected_fusion;
        }
        
        my $fusion_token = join("::", $progname, $sample_name, $fusion);
        
        if ($seen{$fusion_token}) {
            die "Error, already processed fusion [$fusion_token], and these should be unique entries in this file $fusions_file";
        }
        $seen{$fusion_token} = 1 ;
        
        my $val = $J + $S;
        
        push (@{$data{$progname}->{$pred_type}}, $val);
    }
    close $fh;
    
    return(%data);
    
}

####
sub get_unique {
    my (@vals) = @_;
    
    my %v = map { + $_ => 1 } @vals;

    return(keys %v);
}
