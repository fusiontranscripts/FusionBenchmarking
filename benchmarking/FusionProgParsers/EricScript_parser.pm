package EricScript_parser;

use strict;
use warnings;
use Carp;


=ericscript_format

0       GeneName1
1       GeneName2
2       chr1
3       Breakpoint1
4       strand1
5       chr2
6       Breakpoint2
7       strand2
8       EnsemblGene1
9       EnsemblGene2
10      crossingreads
11      spanningreads
12      mean.insertsize
13      homology
14      fusiontype
15      InfoGene1
16      InfoGene2
17      JunctionSequence
18      GeneExpr1
19      GeneExpr2
20      GeneExpr_Fused
21      ES
22      GJS
23      US
24      EricScore

0       PPP1CB
1       SPDYA
2       2
3       28781842
4       +
5       2
6       28783907
7       +
8       ENSG00000213639
9       ENSG00000163806
10      42
11      31
12      210.54
13      ENSG00000186298 (93%)
14      Read-Through
15      protein phosphatase 1, catalytic subunit, beta isozyme [Source:HGNC Symbol;Acc:HGNC:9282]
16      speedy/RINGO cell cycle regulator family member A [Source:HGNC Symbol;Acc:HGNC:30613]
17      tctgcctatagcagccattgtggatgagaagatcttctgttgtcatggagGATTGTCACCAGACCTGCAATCTATGGAGCAGATTCGGAGAATTATGAGA
18      15.81
19      0.03
20      29.76
21      0.6967
22      0.667
23      0.738095238095238
24      0.981308796513694

=cut
    

sub parse_fusion_result_file {
    my ($ericscript_out_file) = @_;

    my @fusions;

    open (my $fh, $ericscript_out_file) or die "Error, cannot open file $ericscript_out_file";
    my $header = <$fh>;
    while (<$fh>) {
        chomp;
        my @x = split(/\t/);

        my $geneA = $x[0];
        my $geneB = $x[1];

        my $junction_count = $x[10];
        my $spanning_count = $x[11];

        my $chrA = $x[2];
        my $brkpt_A = $x[3];
        my $chrB = $x[5];
        my $brkpt_B = $x[6];

        my $struct = {

            geneA => $geneA,
            chrA => $chrA,
            coordA => $brkpt_A,

            geneB => $geneB,
            chrB => $chrB,
            coordB => $brkpt_B,

            span_reads => $spanning_count,
            junc_reads => $junction_count,
        };

        push (@fusions, $struct);
    }

    return(@fusions);
}


1; #EOM

