package InFusion_parser;

use strict;
use warnings;
use Carp;


=infusion_format

0       #id
1       ref1
2       break_pos1
3       region1
4       ref2
5       break_pos2
6       region2
7       num_span  # should be num_split
8       num_paired
9       genes_1
10      genes_2
11      fusion_class

0       5591
1       20
2       35689536
3       [35689535,35689672]
4       1
5       84946639
6       [84946634,84946695]
7       5
8       8210
9       RBL1
10      RPF1
11      inter-chromosomal

=cut


sub parse_fusion_result_file {
    my ($preds_file) = @_;

    my @fusions;

    open (my $fh, $preds_file) or die "Error, cannot open file $preds_file";
    my $header = <$fh>;
    while (<$fh>) {
        chomp;
        my @x = split(/\t/);

        my $geneA = $x[9];
        my $geneB = $x[10];

        $geneA =~ s/;/,/g;
        $geneB =~ s/;/,/g; # others use commas instead of semicolons, so lets be consistent here.

        my $chrA = $x[1];
        my $chrB = $x[4];

        my $brkpt_A = $x[2];
        my $brkpt_B = $x[5];

        my $junction_count = $x[7];
        my $spanning_count = $x[8];

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


