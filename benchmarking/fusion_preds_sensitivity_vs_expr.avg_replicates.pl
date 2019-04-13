#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;

use POSIX;
use Data::Dumper;

my $usage = "\n\n\tusage: $0 preds.collected.scored fusion_TPM_values.dat\n\n";

my $preds_file = $ARGV[0] or die $usage;
my $fusion_TPMs_file = $ARGV[1] or die $usage;

my $max_bin = 10;

main: {

    my %fusion_to_expr_bin = &parse_fusions_into_expr_bins($fusion_TPMs_file);
    
    my %count_ref_fusions_in_bin_by_sample;
    foreach my $fusion_name (keys %fusion_to_expr_bin) {
        
        my $bin = $fusion_to_expr_bin{$fusion_name};
        
        my ($sample, $core_fusion_name) = split(/\|/, $fusion_name);
                
        $count_ref_fusions_in_bin_by_sample{$sample}->{$bin}++;
    }
    
    
    print STDERR Dumper(\%count_ref_fusions_in_bin_by_sample);
    
        
    my %method_to_fusion_pred = &parse_fusion_predictions($preds_file);
    
    
    ## for each method, determine the counts in each bin.
    
    print "#\t" . join("\t", (1..$max_bin)) . "\n";
    foreach my $method (keys %method_to_fusion_pred) {
        
        my $fusion_preds_href = $method_to_fusion_pred{$method};
        my %bin_counts;
        
        foreach my $fusion_pred (keys %$fusion_preds_href) {
            
            my ($sample, $core_fusion_name) = split(/\|/, $fusion_pred);

            my $bin = $fusion_to_expr_bin{$fusion_pred};
            unless (defined $bin) {
                print STDERR Dumper(\%fusion_to_expr_bin);
                print STDERR "Error, fusion [$fusion_pred] not assigned to an expression bin.\n";
                die;
                next;
            }
            
            $bin_counts{$sample}->{$bin}++;
            
            
        }

        my $out_text = "$method";
        for my $bin (1..$max_bin) {
            
            ## want an average across samples.
            my @sample_sensitivities;
            foreach my $sample (keys %count_ref_fusions_in_bin_by_sample) {
                my $num_ref_fusions_in_bin = $count_ref_fusions_in_bin_by_sample{$sample}->{$bin};
                
                unless ($num_ref_fusions_in_bin) {
                    die "Error, no ref fusions in bin [$bin] for sample [$sample] ";
                }
                my $count = $bin_counts{$sample}->{$bin} || 0;
                
                if ($count) {
                    my $sensitivity = sprintf("%.2f", $count / $num_ref_fusions_in_bin * 100);
                    
                    print STDERR "$method\t$sample\t$bin\t$count\t$num_ref_fusions_in_bin\t$sensitivity\%\n";
                    
                    push (@sample_sensitivities, $sensitivity);
                }
            }
            
            my $avg_sensitivity = &average(@sample_sensitivities);
            
            $out_text .= "\t$avg_sensitivity";
        }
        print "$out_text\n";
    }
    
    exit(0);
    
    
}


####
sub average {
    my (@avg_vals) = @_;

    if (scalar(@avg_vals) == 0) {
        return("NA");
    }
    
    my $sum = 0;
    foreach my $val (@avg_vals) {
        $sum += $val;
    }
    my $avg = $sum / scalar(@avg_vals);
   
    return($avg);
}



####
sub parse_fusion_predictions {
    my ($preds_file) = @_;

    my %method_to_preds;

    open (my $fh, $preds_file) or die $!;
    my $header = <$fh>;
    unless ($header =~ /^pred_result\tsample/) {
        die "Error, not finding expected header format for $preds_file";
    }
    
    while (<$fh>) {
        my $line = $_;
        chomp;
        if (/^\#/) { next; }
        my @x = split(/\t/);
        
        my $pred_class = $x[0];
        unless ($pred_class eq "TP") { next; }
        
        my $fusion_name = $x[3];
        my $sample = $x[1];
        my $method = $x[2];
        
        my $effective_fusion_name = pop @x;
        if ($effective_fusion_name ne '.') {
            $fusion_name = $effective_fusion_name;
            my ($sample, $gene_pair) = split(/\|/, $fusion_name);
            my ($geneA, $geneB) = split(/--/, $gene_pair);
            # fusions being evaluated regardless of order of pair
            $fusion_name = $sample . '|' . join("--", sort ($geneA, $geneB));
        }
        else {
            
            $fusion_name = uc $fusion_name;
            # fusions being evaluated regardless of order of pair
            my ($geneA, $geneB) = sort split(/--/, $fusion_name);
            $fusion_name = "$geneA--$geneB";
            $fusion_name = "$sample|$fusion_name";
        }
        
        $method_to_preds{$method}->{$fusion_name} = 1;
    }
    close $fh;
    
    
    return(%method_to_preds);
}
        

####
sub parse_fusions_into_expr_bins {
    my ($fusion_tpm_file) = @_;

    my %fusion_to_TPM_bin;

    open (my $fh, $fusion_tpm_file) or die "Error, cannot open file $fusion_tpm_file";
    while (<$fh>) {
        chomp;
        my ($sample, $fusion, $TPM) = split(/\t/);

        $fusion = uc($fusion);
        my ($geneA, $geneB) = sort split(/--/, $fusion);
        
        $fusion = "$geneA--$geneB";
        
        my $bin = ceil(log($TPM+0.01)/log(2));
        
        if ($bin < 1) {
            $bin = 1;
        }
        elsif ($bin > $max_bin) {
            $bin = $max_bin;
        }
        
        my $fusion_name = join("|", $sample, $fusion);

        $fusion_to_TPM_bin{$fusion_name} = $bin;
    }
    close $fh;

    return(%fusion_to_TPM_bin);
}
