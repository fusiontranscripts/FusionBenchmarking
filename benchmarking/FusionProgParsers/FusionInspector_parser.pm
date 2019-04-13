package FusionInspector_parser;

use strict;
use warnings;
use Carp;

sub parse_fusion_result_file {
    my ($FI_file) = @_;

    my @fusions;

    open (my $fh, $FI_file) or die "Error, cannot open file $FI_file";
    my $header = <$fh>;

    my @x = split(/\t/, $header);
    my %idx;
    for (my $i = 0; $i <= $#x; $i++) {
        $idx{$x[$i]} = $i;
    }

    while (<$fh>) {
        chomp;
        my @x = split(/\t/);

        my $fusion = $x[ $idx{'#FusionName'} ];
        my $junction_reads = $x[ $idx{'JunctionReadCount'} ];
        my $spanning_reads = $x[ $idx{'SpanningFragCount'} ];
        my $fusion_gene_A = $x[ $idx{'LeftGene'} ];
        my $chr_coords_A = $x[ $idx{'LeftBreakpoint'} ];
        my $fusion_gene_B = $x[ $idx{'RightGene'} ];
        my $chr_coords_B = $x[ $idx{'RightBreakpoint'} ];

        my $rest;
        ($fusion_gene_A, $rest) = split(/\^/, $fusion_gene_A);
        ($fusion_gene_B, $rest) = split(/\^/, $fusion_gene_B);

        if ($fusion_gene_A eq $fusion_gene_B) { next; } # no self-fusions

        my ($chrA, $coordA, $orientA) = split(/:/, $chr_coords_A);
        my ($chrB, $coordB, $orientB) = split(/:/, $chr_coords_B);


        my $struct = {
            geneA => $fusion_gene_A,
            chrA => $chrA || ".",
            coordA => $coordA || ".",

            geneB => $fusion_gene_B,
            chrB => $chrB || ".",
            coordB => $coordB || ".",

            span_reads => $spanning_reads,
            junc_reads => $junction_reads,
        };

        push (@fusions, $struct);

    }

    close $fh;

    
    return(@fusions);
}

1; #EOM

