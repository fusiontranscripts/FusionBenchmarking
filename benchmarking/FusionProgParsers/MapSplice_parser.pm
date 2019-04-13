package MapSplice_parser;

use strict;
use warnings;
use Carp;

=mapsplice_format

    Go here: http://www.netlab.uky.edu/p/bioinfo/MapSplice2FusionJunctionFormat

0       chr1~chr1
1       8926354
2       236647038
3       FUSIONJUNC_827
4       2     # junction count  (coverage: number of reads aligned to the fusion junction)
5       -+
6       255,0,0
7       2
8       20,36,169,36,
9       0,227720721,
10      0.693147
11      3
12      CTGC
13      0
14      1
15      0.500000
16      20
17      0
18      10
19      2
20      0
21      2
22      2
23      0
24      0
25      2
26      0
27      8   # spanning count  (encompassing_read pair_count: Number of reads pairs surround the fusion(but not cross the fusion))
28      8926374
29      236647074
30      8926354,64M54P50M|
31      236647038,133M|
32      0
33      0
34      0.553333
35      0.413333
36      114
37      114
38      133
39      133
40      1.79176
41      0.01
42      1
43      114
44      133
45      194
46      100
47      162.5
48      4
49      0
50      4
51      0
52      not_matched
53      not_matched
54      GCGGGTTTGCTCCCAACATC
55      ATTTCTCCTTGATGACATTCTTCAG
56      1
57      from_fusion
58      fusion
59      -,+
60      ENO1,
61      EDARADD,






=cut


sub parse_fusion_result_file {
    my ($mapsplice_out_file) = @_;

    my @fusions;

    my $get_unique_gene_list_sref = sub {
        my ($gene_txt) = @_;

        my %genes;
        my @fields = split(/,/, $gene_txt);
        foreach my $gene (@fields) {
            if ($gene) {
                $genes{$gene} = 1;
            }
        }

        my $unique_gene_list = join(",", keys %genes);

        return($unique_gene_list);
    };


    open (my $fh, $mapsplice_out_file) or die "Error, cannot open file $mapsplice_out_file";
    while (<$fh>) {
        chomp;
        my @x = split(/\t/);

        my $geneA =  &$get_unique_gene_list_sref($x[60]);
        my $geneB =  &$get_unique_gene_list_sref($x[61]);

        my $junction_count = $x[4];
        my $spanning_count = $x[27];

        my ($chrA, $chrB) = split(/\~/, $x[0]);
        unless ($chrA =~ /chr/ && $chrB =~ /chr/) {
            confess "Erorr, didn't parse chr vals from $x[0] of $_";
        }

        $chrA =~ s/chr//;
        $chrB =~ s/chr//;

        my $brkpt_A = $x[1];
        my $brkpt_B = $x[2];

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

