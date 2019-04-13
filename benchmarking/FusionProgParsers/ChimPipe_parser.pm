package ChimPipe_parser;

use strict;
use warnings;
use Carp;

=chimpipe_format

0       juncCoord
1       type
2       filtered
3       reason
4       nbTotal(spanning+consistent)
5       nbSpanningReads
6       nbStaggered
7       percStaggered
8       nbMulti
9       percMulti
10      nbConsistentPE
11      nbInconsistentPE
12      percInconsistentPE
13      overlapA
14      overlapB
15      distExonBoundaryA
16      distExonBoundaryB
17      blastAlignLen
18      blastAlignSim
19      donorSS
20      acceptorSS
21      beg
22      end
23      sameChrStr
24      okGxOrder
25      dist
26      gnIdsA
27      gnIdsB
28      gnNamesA
29      gnNamesB
30      gnTypesA
31      gnTypesB
32      juncSpanningReadsIds
33      consistentPEIds
34      inconsistentPEIds

0       chr16_20331584_-:chr10_102790141_-
1       interchromosomal
2       0
3       na
4       64
5       12
6       10
7       83.3333
8       0
9       0
10      52
11      6
12      10.3448
13      100
14      100
15      0
16      0
17      na
18      na
19      GT
20      AG
21      20331618
22      102790108
23      0
24      na
25      na
26      ENSG00000169347.12
27      ENSG00000186862.13
28      GP2
29      PDZD7
30      protein_coding
31      protein_coding
32      GP2--PDZD7:22513422_1_65674_795_246/2,GP2--PDZD7:6013992_1_65674_795_253/2,GP2--PDZD7:18651184_1_65674_787_244/2,GP2--PDZD7:13513415_1_65674_771_274/2,GP2--PDZD7:18726758_0_65674_309_275/2,GP2--PDZD7:9938499_0_65674_523_267/1,GP2--PDZD7:29000659_1_65674_777_270/2,GP2--PDZD7:4585583_1_65674_763_281/2,GP2--PDZD7:27130619_0_65674_536_263/1,GP2--PDZD7:26083026_1_65674_1000_276/1,GP2--PDZD7:25078555_0_65674_305_265/2,GP2--PDZD7:2697974_1_65674_765_274/2,
33      GP2--PDZD7:22020777_1_65674_952_292,GP2--PDZD7:5371640_0_65674_345_272,GP2--PDZD7:4011265_0_65674_355_269,GP2--PDZD7:15348315_0_65674_361_258,GP2--PDZD7:18040771_0_65674_368_284,GP2--PDZD7:4176469_0_65674_372_264,GP2--PDZD7:1670474_0_65674_386_258,GP2--PDZD7:3112025_0_65674_391_274,GP2--PDZD7:5512129_0_65674_393_277,GP2--PDZD7:26707952_0_65674_401_275,GP2--PDZD7:4428670_0_65674_403_273,GP2--PDZD7:15893714_0_65674_406_261,GP2--PDZD7:8043096_0_65674_421_244,GP2--PDZD7:27141887_0_65674_425_276,GP2--PDZD7:20047998_0_65674_427_284,GP2--PDZD7:27914861_0_65674_431_263,GP2--PDZD7:17601953_0_65674_436_255,GP2--PDZD7:11930670_0_65674_439_265,GP2--PDZD7:1905985_0_65674_447_237,GP2--PDZD7:19507046_0_65674_450_256,GP2--PDZD7:16120283_0_65674_453_264,GP2--PDZD7:1442880_0_65674_459_251,GP2--PDZD7:6188154_0_65674_461_251,GP2--PDZD7:29230170_0_65674_467_248,GP2--PDZD7:17121678_0_65674_468_262,GP2--PDZD7:14680822_0_65674_472_269,GP2--PDZD7:29734871_0_65674_478_254,GP2--PDZD7:3093912_0_65674_481_274,GP2--PDZD7:20847619_0_65674_482_260,GP2--PDZD7:21463824_0_65674_495_275,GP2--PDZD7:18417261_0_65674_495_257,GP2--PDZD7:11186127_0_65674_500_274,GP2--PDZD7:21800267_0_65674_501_282,GP2--PDZD7:5643833_1_65674_962_246,GP2--PDZD7:15187876_1_65674_959_257,GP2--PDZD7:5213969_1_65674_959_264,GP2--PDZD7:29627958_1_65674_925_275,GP2--PDZD7:11277017_1_65674_920_246,GP2--PDZD7:9886284_1_65674_904_261,GP2--PDZD7:3429084_1_65674_880_278,GP2--PDZD7:20034829_1_65674_877_252,GP2--PDZD7:11763602_1_65674_877_243,GP2--PDZD7:14800156_1_65674_875_260,GP2--PDZD7:28172142_1_65674_861_253,GP2--PDZD7:21943178_1_65674_861_275,GP2--PDZD7:22439103_1_65674_857_280,GP2--PDZD7:23310290_1_65674_848_272,GP2--PDZD7:21337748_1_65674_846_270,GP2--PDZD7:24711029_1_65674_837_278,GP2--PDZD7:8330599_1_65674_831_271,GP2--PDZD7:26966622_1_65674_818_272,GP2--PDZD7:22603104_1_65674_811_272,
34      GP2--PDZD7:18724245_0_65674_403_199,GP2--PDZD7:17174393_0_65674_353_244,GP2--PDZD7:7665120_0_65674_506_284,GP2--PDZD7:23403691_0_65674_512_303,GP2--PDZD7:7076342_1_65674_795_262,GP2--PDZD7:2628271_1_65674_791_271,

=cut

sub parse_fusion_result_file {
    my ($chimpipe_results_file) = @_;

    my @fusions;

    open (my $fh, "$chimpipe_results_file") or die $!;
    my $header = <$fh>;
    while (<$fh>) {
        chomp;

        my @x = split(/\t/);

        my $geneA = $x[28];
        my $geneB = $x[29];

        my $breakpoint_info = $x[0];
        my ($A_breakpoint_info, $B_breakpoint_info) = split(/:/, $breakpoint_info);
        my ($chrA, $brkpt_A, $orientA) = split(/_/, $A_breakpoint_info);
        my ($chrB, $brkpt_B, $orientB) = split(/_/, $B_breakpoint_info);

        my $spanning_count = $x[10];
        my $junction_count = $x[5];

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

    close $fh;

    return(@fusions);
}


1; #EOM


