package PRADA_parser;

use strict;
use warnings;
use Carp;


=PRADA_format

0       Gene_A
1       Gene_B
2       A_chr
3       B_chr
4       A_strand
5       B_strand
6       Discordant_n     # span count
7       JSR_n
8       perfectJSR_n
9       Junc_n
10      Position_Consist
11      Junction         # extract junction count
12      Identity
13      Align_Len
14      Evalue
15      BitScore 

0       TRPC4AP
1       MRPL45
2       20
3       17
4       -1
5       1
6       6
7       3
8       3
9       2
10      PARTIALLY
11      TRPC4AP:20:33665849_MRPL45:17:36478009,2|TRPC4AP:20:33665849_MRPL45:17:36476502,1
12      100.00
13      12
14      0.68
15      22.9

=cut



sub parse_fusion_result_file {
    my ($prada_file) = @_;

    my @fusions;

    open (my $fh, $prada_file) or die "Error, cannot open file $prada_file";
    my $header = <$fh>;
    while (<$fh>) {
        chomp;
        my @x = split(/\t/);

        my $span_count = $x[6];

        my $fusion_info = $x[11];
        # CPNE1:20:34243124_PI3:20:43804502,2

        my @fusion_evidence = split(/\|/, $fusion_info);
        foreach my $f_info (@fusion_evidence) {

            $f_info =~ /^(\S+):([^\:]+):(\d+)_(\S+):([^\:]+):(\d+),(\d+)$/ or die "Error, cannot parse $f_info";

            my $geneA = $1;
            my $chrA = $2;
            my $coordA = $3;

            my $geneB = $4;
            my $chrB = $5;
            my $coordB = $6;

            my $junc_reads = $7;


            my $struct = {
                geneA => $geneA,
                chrA => $chrA,
                coordA => $coordA,

                geneB => $geneB,
                chrB => $chrB,
                coordB => $coordB,

                span_reads => $span_count,
                junc_reads => $junc_reads,
            };

            push (@fusions, $struct);
        }
    }


    close $fh;

    return(@fusions);
}

1; #EOM

