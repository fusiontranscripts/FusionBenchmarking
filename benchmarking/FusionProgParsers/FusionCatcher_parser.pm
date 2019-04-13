package FusionCatcher_parser;

use strict;
use warnings;
use Carp;



=FusionCatcher_format

## described at: https://github.com/ndaniel/fusioncatcher/blob/master/doc/manual.md


0       Gene_1_symbol(5end_fusion_partner)
1       Gene_2_symbol(3end_fusion_partner)
2       Fusion_description
3       Counts_of_common_mapping_reads
4       Spanning_pairs         # Count of pair-end reads supporting the fusion
5       Spanning_unique_reads  # Count of unique reads (i.e. unique mapping positions) mapping on the fusion junction. Shortly, here are counted all the reads which map on fusion junction minus the PCR duplicated reads.
6       Longest_anchor_found
7       Fusion_finding_method
8       Fusion_point_for_gene_1(5end_fusion_partner)
9       Fusion_point_for_gene_2(3end_fusion_partner)
10      Gene_1_id(5end_fusion_partner)
11      Gene_2_id(3end_fusion_partner)
12      Exon_1_id(5end_fusion_partner)
13      Exon_2_id(3end_fusion_partner)
14      Fusion_sequence
15      Predicted_effect
16      Predicted_fused_transcripts
17      Predicted_fused_proteins

0       THRA
1       THRA1/BTR
2       no_protein,antisense,known_fusion
3       0
4       74
5       20
6       25
7       BOWTIE
8       17:40086853:+
9       17:48294347:+
10      ENSG00000126351
11      ENSG00000235300
12      ENSE00000863335
13      ENSE00001677074
14      GTGGACTTTGCCAAAAAACTGCCCATGTTCTCCGAG*CAATTTCGAGTGCAAGTGCCACAGTGTCAGCTAAAG
15      CDS(truncated)/exonic(no-known-CDS)

=cut



sub parse_fusion_result_file {
    
    my ($fusionCatcher_file) = @_;
    
    my @fusions;
    
    open (my $fh, $fusionCatcher_file) or die "Error, cannot open file $fusionCatcher_file";
    my $header = <$fh>;
    while (<$fh>) {
        chomp;
        my @x = split(/\t/);
        
        my $geneA = $x[0];
        my $geneB = $x[1];
        
        unless ($geneA =~ /\w/ && $geneB =~ /\w/) { next; } # not scoring fusions not tied to genes.
        
        my $brkpt_A = $x[8];
        my $brkpt_B = $x[9];
        
        my ($chrA, $coordA, $orientA) = split(/:/, $brkpt_A);
        my ($chrB, $coordB, $orientB) = split(/:/, $brkpt_B);
        
        my $spanning_count = $x[4];
        my $junction_count = $x[5];
        
        my $struct = {
            
            geneA => $geneA,
            chrA => $chrA,
            coordA => $coordA,
            
            geneB => $geneB,
            chrB => $chrB,
            coordB => $coordB,
            
            span_reads => $spanning_count,
            junc_reads => $junction_count,
        };
        
        push (@fusions, $struct);
    }
    
    close $fh;
    
    return(@fusions);
}

1; #EOM

