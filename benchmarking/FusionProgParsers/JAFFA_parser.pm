package JAFFA_parser;

use strict;
use warnings;
use Carp;


=JAFFA_format

## described here: https://github.com/Oshlack/JAFFA/wiki/OutputDescription

0       "sample"
1       "fusion genes"
2       "chrom1"
3       "base1"
4       "chrom2"
5       "base2"
6       "gap (kb)"
7       "spanning pairs"    # spanning: The number of read-pairs, where each read in the pair aligns entirely on either side of the breakpoint. You might see a "-" in some of these. This indicates that no spanning pairs were found, but that the contig had only a small amount of flanking sequence to align reads to. i.e. the spanning pairs results may not be indicative of the true support for the fusion event.
8       "spanning reads"    # junction: The number of reads aligning to the breakpoint, with at least 15 bases of flanking sequence either side (by default).
9       "inframe"
10      "aligns"
11      "rearrangement"
12      "contig"
13      "contig break"
14      "classification"
15      "known"

0       "jaffa-direct"
1       "PROP1:FLRT1"
2       "chr5"
3       177421107
4       "chr11"
5       63883691
6       Inf
7       "13674"
8       3261
9       TRUE
10      TRUE
11      TRUE
12      "Locus_1_Transcript_2940/6203_Confidence_0.001_Length_3574"
13      3017
14      "HighConfidence"
15      "-"

=cut
    
sub parse_fusion_result_file {
    my ($jaffa_out_file) = @_;

    my @fusions;

    open (my $fh, $jaffa_out_file) or die "Error, cannot open file $jaffa_out_file";
    my $header = <$fh>;
    while (<$fh>) {
        chomp;
        s/\"//g;

        my @x = split(/,/);

        my $fusion = $x[1];
        my ($geneA, $geneB) = split(/:/, $fusion);

        my $junction_count = $x[8];
        unless ($junction_count =~ /\w/) {
            $junction_count = 0;
        }

        my $spanning_count = $x[7];
        unless ($spanning_count =~ /\w/) {
            $spanning_count = 0;
        }

        my $chrA = $x[2];
        my $brkpt_A = $x[3];
        my $chrB = $x[4];
        my $brkpt_B = $x[5];

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



