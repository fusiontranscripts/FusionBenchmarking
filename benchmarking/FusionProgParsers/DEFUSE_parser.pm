package DEFUSE_parser;

use strict;
use warnings;
use Carp;


=defuse_format

0       cluster_id
1       splitr_sequence
2       splitr_count
3       splitr_span_pvalue
4       splitr_pos_pvalue
5       splitr_min_pvalue
6       adjacent
7       altsplice
8       break_adj_entropy1
9       break_adj_entropy2
10      break_adj_entropy_min
11      breakpoint_homology
12      breakseqs_estislands_percident
13      cdna_breakseqs_percident
14      deletion
15      est_breakseqs_percident
16      eversion
17      exonboundaries
18      expression1
19      expression2
20      gene1
21      gene2
22      gene_align_strand1
23      gene_align_strand2
24      gene_chromosome1
25      gene_chromosome2
26      gene_end1
27      gene_end2
28      gene_location1
29      gene_location2
30      gene_name1
31      gene_name2
32      gene_start1
33      gene_start2
34      gene_strand1
35      gene_strand2
36      genome_breakseqs_percident
37      genomic_break_pos1
38      genomic_break_pos2
39      genomic_strand1
40      genomic_strand2
41      interchromosomal
42      interrupted_index1
43      interrupted_index2
44      inversion
45      library_name
46      max_map_count
47      max_repeat_proportion
48      mean_map_count
49      min_map_count
50      num_multi_map
51      num_splice_variants
52      orf
53      read_through
54      repeat_proportion1
55      repeat_proportion2
56      span_count
57      span_coverage1
58      span_coverage2
59      span_coverage_max
60      span_coverage_min
61      splice_score
62      splicing_index1
63      splicing_index2
64      probability

0       3247
1       GCGCACTTCCCTGAGGACACTGTGGAGCAGAAGGCAGAAAGCGTGGGCAGAATTATGCCTCACACGGAGGTGAGCCCCTGACCAAGACTCCAAAGTCCCACCTCCCGTCACCCAGCTGGGGTGCACCCAGCTGGGACATCGGTTGCTTTCAGTGAGAGAGTCAAATGGCTCAC|CCAGGGCTCTCCCCAGATACCATTTCAAATTCCTGTTAATTTTATTTTAATCCTGAATTCTGAGTTTGAATGTATACCCAGATCAGCCCTGTCTTTGTTTTCACTCACTGGTGTGGATGTAGCATGCCTCCATTAAGCTTTTTATTAACTTGCCTTGTTTTTGTCTCTGGCCTCGTTACCT
2       6
3       0.0891263313789634
4       0.854900607940091
5       0.564814798312889
6       N
7       N
8       3.57167229721571
9       3.4325554405491
10      3.4325554405491
11      0
12      0
13      0
14      Y
15      0
16      N
17      N
18      2876
19      0
20      ENSG00000167107
21      ENSG00000227011
22      +
23      -
24      17
25      17
26      48552206
27      51065012
28      intron
29      downstream
30      ACSF2
31      C17orf112
32      48503519
33      51062880
34      +
35      +
36      0
37      48548600
38      51089613
39      +
40      -
41      N
42      -
43      -
44      N
45      defuse_outdir
46      1
47      0
48      1
49      1
50      0
51      1
52      N
53      N
54      0
55      0
56      8
57      1.23121459994238
58      1.40196698971541
59      1.40196698971541
60      1.23121459994238
61      2
62      -
63      -
64      0.510155154639065

=cut

    


sub parse_fusion_result_file {
    my ($defuse_out_file) = @_;

    my @fusions;

    open (my $fh, $defuse_out_file) or die "Error, cannot open file $defuse_out_file";
    my $header = <$fh>;
    while (<$fh>) {
        chomp;
        my @x = split(/\t/);

        my $geneA = $x[30];
        my $geneB = $x[31];

        my $junction_count = $x[2]; # splitr_count
        unless ($junction_count =~ /\w/) {
            $junction_count = 0;
        }

        my $spanning_count = $x[56]; # span_count
        unless ($spanning_count =~ /\w/) {
            $spanning_count = 0;
        }

        my $chrA = $x[24];
        my $brkpt_A = $x[37];
        my $chrB = $x[25];
        my $brkpt_B = $x[38];

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

