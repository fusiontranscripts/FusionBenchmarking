package SOAPfuse_parser;

use strict;
use warnings;
use Carp;

sub parse_fusion_result_file {
    my ($soap_file) = @_;
    
=soapfuse_format

        0       up_gene
        1       up_chr
        2       up_strand
        3       up_Genome_pos
        4       up_loc
        5       dw_gene
        6       dw_chr
        7       dw_strand
        8       dw_Genome_pos
        9       dw_loc
        10      Span_reads_num     # S
        11      Junc_reads_num     # J
        12      Fusion_Type
        13      down_fusion_part_frame-shift_or_not

        0       SLMO2
        1       chr20
        2       -
        3       57610027
        4       M
        5       ATP5E
        6       chr20
        7       -
        8       57605484
        9       E
        10      3
        11      4
        12      INTRACHR-SS-OGO-0GAP
        13      NA


=cut

    ;


    my @fusions;

    open (my $fh, $soap_file) or die "Error, cannot open file $soap_file";
    my $header = <$fh>;
    while (<$fh>) {
        chomp;
        my @x = split(/\t/);

        my $geneA = $x[0];
        my $geneB = $x[5];

        $geneA =~ s/SOAPfuse.*//;
        $geneB =~ s/SOAPfuse.*//;

        my $struct = {
            geneA => $geneA,
            chrA => $x[1],
            coordA => $x[3],

            geneB => $geneB,
            chrB => $x[6],
            coordB => $x[8],

            span_reads => $x[10],
            junc_reads => $x[11],

        };


        push (@fusions, $struct);
    }


    return(@fusions);
}


1; #EOM

