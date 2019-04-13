package FusionCatcher_KP_parser;

use strict;
use warnings;
use Carp;



=FusionCatcher_format

## described at: https://github.com/ndaniel/fusioncatcher/blob/master/doc/manual.md

0       Fusion_gene_1
1       Fusion_gene_2
2       Count_paired-end_reads
3       Fusion_gene_symbol_1
4       Fusion_gene_symbol_2
5       Fusion_description
6       Analysis_status
7       Counts_of_common_mapping_reads

0       ENSG00000175121
1       ENSG00000178053
2       9465
3       WFDC5
4       MLF1
5       
6       further_analysis
7       0



=cut



sub parse_fusion_result_file {
    
    my ($fusionCatcher_file) = @_;
    
    my @fusions;
    
    open (my $fh, $fusionCatcher_file) or die "Error, cannot open file $fusionCatcher_file";
    my $header = <$fh>;
    while (<$fh>) {
        chomp;
        my @x = split(/\t/);
        
        my $geneA = $x[3];
        my $geneB = $x[4];
        
        unless ($geneA =~ /\w/ && $geneB =~ /\w/) { next; } # not scoring fusions not tied to genes.
        
        my $brkpt_A = $x[8];
        my $brkpt_B = $x[9];
        
        my $junction_count = $x[2];
        
        my $struct = {
            
            geneA => $geneA,
            chrA => "NA",
            coordA => "NA",
            
            geneB => $geneB,
            chrB => "NA",
            coordB =>  "NA",
            
            span_reads => 0, # treat total count as junction here.
            junc_reads => $junction_count,
        };
        
        push (@fusions, $struct);
    }
    
    close $fh;
    
    return(@fusions);
}

1; #EOM

