package ChimeraScan_parser;

use strict;
use warnings;
use Carp;

=chimerascan_format

0       #chrom5p
1       start5p
2       end5p
3       chrom3p
4       start3p
5       end3p
6       chimera_cluster_id
7       score
8       strand5p
9       strand3p
10      transcript_ids_5p
11      transcript_ids_3p
12      genes5p
13      genes3p
14      type
15      distance
16      total_frags
17      spanning_frags
18      unique_alignment_positions
19      isoform_fraction_5p
20      isoform_fraction_3p
21      breakpoint_spanning_reads
22      chimera_ids

0       chr17
1       38219062
2       38243105
3       chr17
4       46371708
5       46385190
6       CLUSTER41
7       138
8       +
9       +
10      ENST00000450525.2:0-1066,ENST00000450525.2:0-1213,ENST00000584985.1:0-1155,ENST00000546243.1:0-977,ENST00000394121.4:0-1131,ENST00000264637.4:0-1155,ENST00000546243.1:0-1124,ENST00000584985.1:0-1302,ENST00000394121.4:0-1278,ENST00000264637.4:0-1302
11      ENST00000421610.2:169-667,ENST00000604191.1:0-570,ENST00000421610.2:0-667
12      THRA
13      AC090627.1
14      Intrachromosomal
15      8121588
16      138
17      71
18      129
19      0.896103896104
20      1.0
21      >4910959/2;pos=4;strand=-,AAACTGCCCATGTTCTCCGAGCAATTTCGAGTGCAAGTGCCACAGTGTCA,>2034127/1;pos=0;strand=-,CAAAAAACTGCCCATGTTCTCCGAGCAATTTCGAGTGCAAGTGCCACAGT,>774891/2;pos=2;strand=-,AAAAACTGCCCATGTTCTCCGAGCAATTTCGAGTGCAAGTGCCACAGTGT,>19849147/1;pos=8;strand=-,TGCCCATGTTCTCCGAGCAATTTCGAGTGCAAGTGCCACAGTGTCAGCTG,>10432608/1;pos=7;strand=-,CTGCCCATGTTCTCCGAGCAATTTCGAGTGCAAGTGCCACAGTGTCAGCA,>820632/1;pos=5;strand=-,AACTGCCCATGTTCTCCGAGCAATTTCGAGTGCAAGTGCCACAGTGTCAG,>5743073/2;pos=3;strand=-,AAAACTGCCCATGTTCTCCGAGCAATTTCGAGTGCAAGTGCCACAGTGTC,>9753659/1;pos=7;strand=-,CTGCCCATGTTCTCCGAGCAATTTCGAGTGCAAGTGCCACAGTGTCAGCT,>20253102/2;pos=13;strand=-,ATGTTCTCCGAGCAATTTCGAGTGCAAGTGCCGCAGTGTCAGCTAAAGAA,>15409265/1;pos=6;strand=-,ACTGCCCATGTTCTCCGAGCAATTTCGAGTGCAAGTGCCACAGTGTCAGC,>7246100/2;pos=1;strand=-,AAAAAACTGCCCATGTTCTCCGAGCAATTTCGAGTGCAAGTGCCACAGTG,>13967970/1;pos=15;strand=-,GTTCTCCGAGCAATTTCGAGTGCAAGTGCCACAGTGTCAGCTAAAGAAAC,>12125678/2;pos=1257;strand=+,CACCCGTGTGGTGGACTTTGCCAAAAAACTGCCCATGTTCTCCGAGCAAT,>17295693/1;pos=1259;strand=+,CCCGTGTGGTGGACTTTGCCAAAAAACTGCCCATGTTCTCCGAGCAATTT,>563772/1;pos=1260;strand=+,CCGTGTGGTGGACTTTGCCAAAAAACTGCCCATGTTCTCCGAGCAATTTC,>3811711/2;pos=1264;strand=+,GTGGTGGACTTTGCCAAAAAACTGCCCATGTTCTCCGAGCAATTTCGAGT,>12114145/1;pos=1267;strand=+,GTGGACTTTGCCAAAAAACTGCCCATGTTCTCCGAGCAATTTCGAGTGCA,>4357847/2;pos=1268;strand=+,TGGACTTTGCCAAAAAACTGCCCATGTTCTCCGAGCAATTTCGAGTGCAA,>8496244/2;pos=1270;strand=+,GACTTTGCCAAAAAACTGCCCATGTTCTCCGAGCAATTTCGAGTGCAAGT,>20818261/1;pos=1272;strand=+,CTTTGCCAAAAAACTGCCCATGTTCTCCGAGCAATTTCGAGTGCAAGTGC,>10659063/2;pos=1272;strand=+,CTTTGCCAAAAAACTGCCCATGTTCTCCGAGCAATTTCGAGAGCAAGTGC,>7520969/1;pos=1273;strand=+,TTTGCCAAAAAACTGCCCATGTTCTCCGAGCAATTTCGAGTGCAAGTGCC,>10039588/1;pos=1282;strand=+,AAACTGCCCATGTTCTCCGAGCAATTTCGAGTGCAAGTGCAACAGTGTCA
22      C5666846,C5666847,C6157374,C4569163,C3378772,C4569165,C3378770,C3378771,C5666883,C0478383,C0478385,C0478384,C5666848,C6157506,C0478515,C6157375,C6157376,C4569164,C4569205,C3378807

=cut
    


sub parse_fusion_result_file {
    my ($chimeraScan_file) = @_;

    my @fusions;

    open (my $fh, $chimeraScan_file) or die "Error, cannot open file $chimeraScan_file";
    my $header = <$fh>;
    while (<$fh>) {
        if (/^\#/) { next; }
        chomp;
        my @x = split(/\t/);

        my $chrA = $x[0];
        my $chrA_start = $x[1];
        my $chrA_end = $x[2];

        my $chrB = $x[3];
        my $chrB_start = $x[4];
        my $chrB_end = $x[5];

        my $chrA_strand = $x[8];
        my $chrB_strand = $x[9];


        my $geneA = $x[12];
        my $geneB = $x[13];


        my $brkpt_A = ($chrA_strand eq '+') ? $chrA_end : $chrA_start;
        my $brkpt_B = ($chrB_strand eq '+') ? $chrB_end : $chrB_start;


        my $total_frags = $x[16];

        my $junction_count = $x[17];
        my $spanning_count = $total_frags - $junction_count;


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

