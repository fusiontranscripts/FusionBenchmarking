package NFuse_parser;

use strict;
use warnings;
use Carp;


=nFUSE_format

0       cluster_id
1       adjacent
2       altsplice
3       break_adj_entropy1
4       break_adj_entropy2
5       break_adj_entropy_min
6       breakpoint_homology
7       breakpos1
8       breakpos2
9       cdna_breakseqs_percident
10      chromosome1
11      chromosome2
12      defuse_probability
13      deletion
14      est_breakseqs_percident
15      estisland_breakseqs_percident
16      eversion
17      exonboundaries
18      gene1
19      gene2
20      gene_align_strand1
21      gene_align_strand2
22      gene_chromosome1
23      gene_chromosome2
24      gene_end1
25      gene_end2
26      gene_location1
27      gene_location2
28      gene_name1
29      gene_name2
30      gene_start1
31      gene_start2
32      gene_strand1
33      gene_strand2
34      genome_breakseqs_percident
35      genomic_break_pos1
36      genomic_break_pos2
37      genomic_strand1
38      genomic_strand2
39      interchromosomal
40      inversion
41      library_name
42      max_map_count
43      mean_map_count
44      min_map_count
45      num_multi_map
46      num_splice_variants
47      orf
48      readthrough
49      reference1
50      reference2
51      repeat_list1
52      repeat_list2
53      repeat_proportion1
54      repeat_proportion2
55      repeat_proportion_max
56      sequence
57      span_count        # spanning count
58      span_coverage1
59      span_coverage2
60      span_coverage_max
61      span_coverage_min
62      splice_score
63      splitreads_count    # junction count
64      splitreads_min_pvalue
65      splitreads_pos_pvalue
66      splitreads_span_pvalue
67      strand1
68      strand2

0       16780
1       N
2       N
3       3.46807512488172
4       3.60632674564779
5       3.46807512488172
6       0
7       393
8       150364072
9       0
10      3
11      6
12      0.798023102489623
13      N
14      0
15      0
16      N
17      N
18      ENSG00000183396
19      ENSG00000213091
20      -
21      +
22      3
23      6
24      48659288
25      150364489
26      coding
27      intron
28      TMEM89
29      PHBP1
30      48658192
31      150363682
32      -
33      +
34      0
35      48658896
36      150364072
37      +
38      +
39      Y
40      N
41      tmp.defuse_outdir
42      2
43      1.33333333333333
44      1
45      2
46      1
47      N
48      N
49      ENSG00000183396|ENST00000330862
50      6
51      -
52      -
53      0
54      0
55      0
56      CCCACTCTGGGTGGAAGTCCCCTTTATTTGGATTTGCCGCTGGGTGGCTAGATGACGTAGGTGGCCTTCGATGTGGACCAGGAGGGCATCCAGCATGTGCAGGACCCCACGGAGCAGGGTGTGGTCTGAGATTGGGGCCCGCCGTTTCCAGGGTCCGCAGGGCTCAGTGGTCACCTGCGGATGC|ACCACTGACTTGAGGATCTCAGTCATGATGGACGTCAGCACACGCTCATCATAGTCCTCTCCGGTGATGGCGAAGATGCGAGGAAGCTGGCTAGAGACGGGCCGGAAGAGGATGCACAGTGTGATGTTGACATTCTGTAAATATTTGCTACCAGTGATGACTGGCACAGTA
57      6
58      0.780927305360403
59      0.615731144611087
60      0.780927305360403
61      0.615731144611087
62      1
63      1655
64      0.717074880359308
65      0.58076168734171
66      0.844296742119671
67      -
68      +


=cut
    

sub parse_fusion_result_file {
    my ($nFUSE_out_file) = @_;

    my @fusions;

    open (my $fh, $nFUSE_out_file) or die "Error, cannot open file $nFUSE_out_file";
    my $header = <$fh>;
    while (<$fh>) {
        chomp;
        my @x = split(/\t/);

        my $geneA = $x[28];
        my $geneB = $x[29];

        my $chrA = $x[10];
        my $chrB = $x[11];

        my $brkpt_A = $x[35];
        my $brkpt_B = $x[36];

        my $spanning_count = $x[57];
        my $junction_count = $x[63];

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

