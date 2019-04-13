#!/usr/bin/env perl

use strict;
use warnings;
use lib ($ENV{EUK_MODULES});
use TiedHash;

my $usage = "\n\n\tusage: $0 preds_collected.scored TP_fusions.txt\n\n";

my $fusion_summary_file = $ARGV[0] or die $usage;
my $TP_fusions_file = $ARGV[1] or die $usage;


#my $paralogs_file = "/seq/regev_genome_portal/RESOURCES/human/Hg19/gencode.v19/BLASTN_WSIZE11/gencode.paralogs";
my $paralogs_file = "/seq/regev_genome_portal/RESOURCES/CTAT_GENOME_LIB/GRCh37_gencode_v19_FL3/blastn/paralog_clusters.dat";

my $blast_idx_file = "/seq/regev_genome_portal/RESOURCES/CTAT_GENOME_LIB/GRCh37_gencode_v19_FL3/blast_pairs.idx";

my $BLAST_PAIRS_IDX = new TiedHash( { use => $blast_idx_file } );



main: {
    
    my %paralogs = &parse_paralogs($paralogs_file);
    
    my %prog_to_calls = &parse_fusions($fusion_summary_file);

    my %TP_fusions = &parse_TP_fusions($TP_fusions_file);

    my %gene_in_TP_fusion;
    my %para_of_TP;
    foreach my $fusion (keys %TP_fusions) {
        
        my ($sample, $fusion_name) = split(/\|/, $fusion);
        my ($geneA, $geneB) = split(/--/, $fusion_name);
        
        foreach my $gene ($geneA, $geneB) {
            $gene_in_TP_fusion{"$sample|$gene"}->{$fusion}++;    
            if (my $para_aref = $paralogs{$gene}) {
                foreach my $para (@$para_aref) {
                    if ($para ne $gene) {
                        $para_of_TP{"$sample|$para"}->{"$para|para|$gene-of-$fusion"}++;
                    }
                }
            }
        }
    }
    
    foreach my $program (keys %prog_to_calls) {

        my @preds = @{$prog_to_calls{$program}};
        
        my @FP_preds;
        my %called_TP;
        foreach my $pred (@preds) {
            if ($pred->{TPorFP} eq "TP") {
                my ($sample_name, $fusion_name) = split(/\|/, $pred->{fusion});
                my ($geneA, $geneB) = split(/--/, $fusion_name);
                
                $called_TP{"$sample_name|$geneA"}->{"$sample_name|$fusion_name"}++;
                $called_TP{"$sample_name|$geneB"}->{"$sample_name|$fusion_name"}++;
                
            }
            elsif ($pred->{TPorFP} eq "FP") {
                push (@FP_preds, $pred);
            }
        }
        
        foreach my $FP_pred (@FP_preds) {
            my @annots;
            my ($sample, $fusion_name) = split(/\|/, $FP_pred->{fusion});
            my ($geneA, $geneB) = split(/--/, $fusion_name);
            
            foreach my $gene ($geneA, $geneB) {
                
                my ($alt_gene) = grep { $_ ne $gene } ($geneA, $geneB);
                
                if (my $href = $called_TP{"$sample|$gene"}) {
                    my @f = keys %$href;
                    my $annot = "[$gene called TP in " . join(",", @f) . "]";
                    push (@annots, $annot);
                
                    
                }
                
                if (my $href = $gene_in_TP_fusion{"$sample|$gene"}) {
                    my @f = keys %$href;
                    my $annot = "[$gene in Truth set as: " . join(",", @f) . "]";
                    push (@annots, $annot);
                
                    foreach my $TP_f (@f) {
                        $TP_f =~ /\|(\S+)--(\S+)/;
                        my ($gA, $gB) = ($1, $2);
                        my ($other_alt) = grep { $_ ne $gene } ($gA, $gB);
                        if (my $hit = $BLAST_PAIRS_IDX->get_value("$other_alt--$alt_gene")) {
                            push (@annots, "BLAST:$hit");
                        }
                    }
                    
                }


                if (my $href = $para_of_TP{"$sample|$gene"}) {
                    my @f = keys %$href;
                    my $annot = "[$gene is PARALOG of: " . join(",", @f) . "]";
                    push (@annots, $annot);
                }
            }
            
            print $FP_pred->{line} . "\t" . join(";", @annots) . "\n";
            
        } # eofor FP_pred
            

    }

    
    exit(0);
    

}

####
sub parse_TP_fusions {
    my ($TP_fusions_file) = @_;

    my %fusions;

    open (my $fh, $TP_fusions_file) or die $!;
    while (<$fh>) {
        chomp;
        my $fusion = $_;
        $fusions{$fusion}++;
    }
    close $fh;

    return(%fusions);
}




####
sub parse_fusions {
    my ($fusions_file) = @_;

    my %fusions;

    open (my $fh, $fusions_file) or die $!;
    while (<$fh>) {
        chomp;
        if (/^\#/) { next; }
        my $line = $_;
        
        my ($TPorFP, $prog, $sample, $fusion_name, $J, $S, $explanation) = split(/\t/);
        
        unless ($TPorFP =~ /^(TP|FP)$/) { next; }
        
        my $fusion_struct = { fusion => "$sample|$fusion_name",
                              prog => $prog,
                              J => $J,
                              S => $S,
                              TPorFP => $TPorFP,
                              line => $line,
        };

        push (@{$fusions{$prog}}, $fusion_struct);
    }
    close $fh;
    
    return(%fusions);
}


####
sub parse_paralogs {
    my ($paralog_clusters) = @_;

    my %paralogs;
    
    open (my $fh, $paralog_clusters) or die $!;
    while (<$fh>) {
        chomp;
        my @x = split(/\s+/);
        my $para_list_aref = [@x];
        foreach my $gene (@x) {
            $paralogs{$gene} = $para_list_aref;
        }
    }
    close $fh;

    return(%paralogs);
}

