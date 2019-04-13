package STARFusion_parser;

use strict;
use warnings;
use Carp;


=STARFusion_format

0       #FusionName
1       JunctionReadCount
2       SpanningFragCount
3       SpliceType
4       LeftGene
5       LeftBreakpoint
6       RightGene
7       RightBreakpoint
8       LargeAnchorSupport
9       LeftBreakDinuc
10      LeftBreakEntropy
11      RightBreakDinuc
12      RightBreakEntropy

0       THRA--AC090627.1
1       76
2       104
3       ONLY_REF_SPLICE
4       THRA^ENSG00000126351.8
5       chr17:38243106:+
6       AC090627.1^ENSG00000235300.3
7       chr17:46371709:+
8       YES_LDAS
9       GT
10      1.8892
11      AG
12      1.9656


=cut



sub parse_fusion_result_file {
    my ($starFusion_file) = @_;

    my @fusions;

    open (my $fh, $starFusion_file) or die "Error, cannot open file $starFusion_file";
    while (<$fh>) {
        if (/^\#/) { next; }

        chomp;

        my ($fusion, $junction_reads, $spanning_reads, $splice_type,
            $fusion_gene_A, $chr_coords_A,
            $fusion_gene_B, $chr_coords_B) = split(/\t/);

        my $rest;
        ($fusion_gene_A, $rest) = split(/\^/, $fusion_gene_A);
        ($fusion_gene_B, $rest) = split(/\^/, $fusion_gene_B);

        if ($fusion_gene_A eq $fusion_gene_B) { next; } # no self-fusions

        my ($chrA, $coordA, $orientA) = split(/:/, $chr_coords_A);
        my ($chrB, $coordB, $orientB) = split(/:/, $chr_coords_B);


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

