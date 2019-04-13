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
    
    my %count_ref_fusions_in_bin;
    foreach my $bin (values %fusion_to_expr_bin) {
        $count_ref_fusions_in_bin{$bin}++;
    }

    #print Dumper(\%count_ref_fusions_in_bin);
    print STDERR "counts of ref fusions per bin:\n";
    for my $bin (1..$max_bin) {
        my $count = $count_ref_fusions_in_bin{$bin} || 0;
        print STDERR join("\t", $bin, $count) . "\n";
    }
        
    my %method_to_fusion_pred = &parse_fusion_predictions($preds_file);
    
    
    ## for each method, determine the counts in each bin.
    
    print "#\t" . join("\t", (1..$max_bin)) . "\n";
    foreach my $method (keys %method_to_fusion_pred) {
        
        my $fusion_preds_href = $method_to_fusion_pred{$method};
        my %bin_counts;
        
        foreach my $fusion_pred (keys %$fusion_preds_href) {
            
            my $bin = $fusion_to_expr_bin{$fusion_pred};
            unless (defined $bin) {
                print STDERR "Error, fusion \"$fusion_pred\" not assigned to an expression bin.\n";
                next;
            }
            
            $bin_counts{$bin}++;
            
        }

        print "$method";
        for my $bin (1..$max_bin) {
            my $count = $bin_counts{$bin} || 0;
            my $num_ref_fusions_in_bin = $count_ref_fusions_in_bin{$bin};

            my $sensitivity = sprintf("%.2f", $count / $num_ref_fusions_in_bin * 100);
            print "\t$sensitivity";
        }
        print "\n";
    }

    exit(0);
    
    
}

####
sub parse_fusion_predictions {
    my ($preds_file) = @_;

    my %method_to_preds;

    open (my $fh, $preds_file) or die $!;
    while (<$fh>) {
        my $line = $_;
        chomp;
        if (/^\#/) { next; }
        my @x = split(/\t/);
        
        my $pred_class = $x[0];
        unless ($pred_class eq "TP") { next; }
        
        my $fusion_name = $x[3];
        my $sample = $x[2];
        my $method = $x[1];
        
        if ($line =~ /chr_mapping_to_first_encounter_of_TP_\S+\|(\S+--\S+)/) {
            $fusion_name = $1;
        }
        
        $fusion_name = uc $fusion_name;
        my ($geneA, $geneB) = sort split(/--/, $fusion_name);
        $fusion_name = "$geneA--$geneB";
        
        $fusion_name = "$sample|$fusion_name";
        
        $method_to_preds{$method}->{$fusion_name} = 1;
    }
    close $fh;
    
    
    return(%method_to_preds);
}
        

####
sub parse_fusions_into_expr_bins {
    my ($fusion_tpm_file) = @_;

    my %fusion_to_TPM_bin;

    open (my $fh, $fusion_tpm_file) or die $!;
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
