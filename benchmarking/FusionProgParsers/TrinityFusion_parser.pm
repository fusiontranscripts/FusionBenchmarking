package TrinityFusion_parser;

use strict;
use warnings;
use Carp;


=TrinityFusion_format

0       #FusionName
1       JunctionReadCount
2       SpanningFragCount
3       trans_acc
4       trans_brkpt
5       LeftGene
6       LeftBreakpoint
7       RightGene
8       RightBreakpoint
9       SpliceType
10      annots

0       CWC22--AC104532.2
1       3105
2       9676
3       TRINITY_DN196_c0_g1_i1
4       284-283
5       CWC22
6       chr2:180835228
7       AC104532.2
8       chr19:5914396
9       ONLY_REF_SPLICE
10      ["INTERCHROMOSOMAL[chr2--chr19]"]

=cut


sub parse_fusion_result_file {
    my ($file) = @_;

    my @fusions;
    
    open (my $fh, $file) or die "Error, cannot open file $file";
    while (<$fh>) {
        if (/^\#/) { next; }
        
        chomp;

        my @x = split("\t");
        my $fusion_gene_A = $x[5];
        my $fusion_gene_B = $x[7];
        
        if ($fusion_gene_A eq $fusion_gene_B) { next; } # no self-fusions

        my $chr_coords_A = $x[6];
        my $chr_coords_B = $x[8];
        
        my ($chrA, $coordA, $orientA) = split(/:/, $chr_coords_A);
        my ($chrB, $coordB, $orientB) = split(/:/, $chr_coords_B);

        my $junction_reads = $x[1];
        my $spanning_reads = $x[2];
        
        my $struct = {
            geneA => $fusion_gene_A,
            chrA => $chrA || ".",
            coordA => $coordA || ".",

            geneB => $fusion_gene_B,
            chrB => $chrB || ".",
            coordB => $coordB || ".",

            span_reads => $spanning_reads,
            junc_reads => $junction_reads,
        };
        
        push (@fusions, $struct);

    }

    close $fh;

    return(@fusions);
}


1; #EOM

