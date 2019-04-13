package ARRIBA_parser;

use strict;
use warnings;
use Carp;


=ARRIBA_format


0       #gene1
1       gene2
2       strand1(gene/fusion)
3       strand2(gene/fusion)
4       breakpoint1
5       breakpoint2
6       site1
7       site2
8       type
9       direction1
10      direction2
11      split_reads1
12      split_reads2
13      discordant_mates
14      coverage1
15      coverage2
16      confidence
17      closest_genomic_breakpoint1
18      closest_genomic_breakpoint2
19      filters
20      fusion_transcript
21      reading_frame
22      peptide_sequence
23      read_identifiers


0       PID1
1       DAP
2       -/-
3       -/-
4       2:230020534
5       5:10681281
6       splice-site
7       splice-site
8       translocation
9       upstream
10      downstream
11      305
12      304
13      300
14      8156
15      6135
16      high
17      .
18      .
19      duplicates(79),mismatches(9)
20      ACACCGACCCCAGATGTAAAGCGGGACCCCAGCCCCTCGCCCCCCGGCGCGATCGACAGTCTCGCCAGCGTCTCCTCTGCCAAAACCCAGGGCTGGAAGATGTGGCAGCCGGCCACGGAGCGCCTGCAG___CACTTTCAGACCATGCTGAAGTCTAAATTGAATGTCTTAACACTGAAAAAGGAACCTCTCCCAGCGGTCATCTTCCATGAGCCGGAGGCCATTGAGCTGTGCACGACCACACCGCTGATGAAGACAAGGACTCACAGTGGCTGCAAG|GGTGACAAAGATTTCCCCCCGGCGGCTGCGCAGGTGGCTCACCAGAAGCCGCATGCCTCCATGGACAAGCATCCTTCCCCAAGAACCCAGCACATCCAGCAGCCACGCAAGTGAGCCTGGAGTCCACCAGCCTGCCCCATGGCCCCGGCTCTGCTGCACTTGGTATTTCCCTGACAGAGAGAACCAGCAGTTTCGCCCAAATCCTACTCTGCTGGGAAATCTAAGGCAAAACCAAGTGCTCTGTCCTTTGCCTTACATTTCCATATTTAAAACTAGAAACAGCTCCAGC
21      in-frame
22      MWQPATERLQHFQTMLKSKLNVLTLKKEPLPAVIFHEPEAIELCTTTPLMKTRTHSGCK|GDKDFPPAAAQVAHQKPHASMDKHPSPRTQHIQQPRK*
23      .


=cut



sub parse_fusion_result_file {
    my ($file) = @_;

    my @fusions;

    open (my $fh, $file) or die "Error, cannot open file $file";
    my $header = <$fh>;
    while (<$fh>) {
        chomp;
        my @x = split(/\t/);

        my $geneA = $x[0];
        my $geneB = $x[1];

        $geneA =~ s/\(\d+\)//g;
        $geneB =~ s/\(\d+\)//g;
        
        my $coord_info_A = $x[4];
        my ($chrA, $coordA) = split(/:/, $coord_info_A);

        my $coord_info_B = $x[5];
        my ($chrB, $coordB) = split(/:/, $coord_info_B);

        my $junction_read_count = $x[11] + $x[12];
        my $spanning_frags = $x[13];

        
        
        my $struct = {
            geneA => $geneA,
            chrA => $chrA,
            coordA => $coordA,

            geneB => $geneB,
            chrB => $chrB,
            coordB => $coordB,

            span_reads => $spanning_frags,
            junc_reads => $junction_read_count,
        };

        push (@fusions, $struct);

    }

    close $fh;

    return(@fusions);
}


1; #EOM

