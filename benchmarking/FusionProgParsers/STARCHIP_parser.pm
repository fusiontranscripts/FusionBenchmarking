package STARCHIP_parser;

use strict;
use warnings;
use Carp;


=STARCHIP_format

0       Partner1
1       Partner2
2       SpanningReads
3       SplitReads
4       AvgAS
5       NearGene1
6       Distance1
7       NearGene2
8       Distance2
9       ConsensusSeq

0       chr9:133729451:-
1       chr22:23632600:-
2       21
3       18
4       87.4
5       ABL1
6       0
7       BCR
8       0
9       gggctctatgggtttctgaatgtcatcgtccactcagccactggatttaagcagagttcaaaagcccttcagcggccagtagcatctgactttgagcctcagggtctgagtgaagccgctcg

=cut



sub parse_fusion_result_file {
    my ($file) = @_;

    my @fusions;

    open (my $fh, $file) or die "Error, cannot open file $file";
    my $header = <$fh>;
    while (<$fh>) {
        if (/^\#/) { next; }
        chomp;
        my ($chr_coords_A, $chr_coords_B,
            $span_count, $junc_count,
            $avgAS,
            $geneA,
            $distA,
            $geneB,
            $distB,
            $seq) = split(/\t/);
        
        my ($chrA, $coordA, $orientA) = split(/:/, $chr_coords_A);
        my ($chrB, $coordB, $orientB) = split(/:/, $chr_coords_B);

        my $struct = {
            geneA => $geneA,
            chrA => $chrA,
            coordA => $coordA,

            geneB => $geneB,
            chrB => $chrB,
            coordB => $coordB,

            span_reads => $span_count,
            junc_reads => $junc_count,
        };
        
        push (@fusions, $struct);

    }

    close $fh;

    return(@fusions);
}


1; #EOM

