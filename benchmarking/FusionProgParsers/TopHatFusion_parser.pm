package TopHatFusion_parser;

use strict;
use warnings;
use Carp;

sub parse_fusion_result_file {
    my ($tophatfusion_file) = @_;

=tophatfusion_format

from: http://tophat.cbcb.umd.edu/data/result.html#detail

1. Sample name in which a fusion is identified 
2. Gene on the "left" side of the fusion 
3. Chromosome ID on the left 
4. Coordinates on the left 
5. Gene on the "right" side 
6. Chromosome ID on the right 
7. Coordinates on the right 
8. Number of spanning reads 
9. Number of spanning mate pairs 
10. Number of spanning mate pairs where one end spans a fusion 
If you follow the the 9th column, it shows coordinates "number1:number2" where one end is located at a distance of "number1" bases from the left genomic coordinate of a fusion and "number2" is similarly defined

0       sample_1
1       PNRC2
2       chr1
3       24289902
4       DGKD
5       chr2
6       234263228
7       147  # J
8       134  # S
9       102
10      953.07

=cut

    ;


    my @fusions;

    open (my $fh, $tophatfusion_file) or die "Error, cannot open file $tophatfusion_file";
    while (<$fh>) {
        chomp;
        my @x = split(/\t/);

        my $struct = {

            geneA => $x[1],
            chrA => $x[2],
            coordA => $x[3],

            geneB => $x[4],
            chrB => $x[5],
            coordB => $x[6],

            span_reads => $x[8],
            junc_reads => $x[7],

        };

        push (@fusions, $struct);
    }

    close $fh;

    return(@fusions);
}


1; #EOM

