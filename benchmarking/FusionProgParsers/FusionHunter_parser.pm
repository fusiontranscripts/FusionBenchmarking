package FusionHunter_parser;

use strict;
use warnings;
use Carp;

=fusionhunter_format:

# Fusion: FusionHunter_temp/R4 chr16:46835908-46865392+chr14:32798428-33302317[+-](44)
-> 9169803_1_10403_731_269/2                 AGATGTCAATTTCCTTTTCCTGTTTCT AGATTCCTTTCCCATCTTCTTTT                    chr16:46836956-46836982 chr14:33243077-33243099  C16orf87 x AKAP6   known x known
-> 9138403_0_10403_3604_270/1                    GTCAATTTCCTTTTCCTGTTTCT AGATTCCTTTCCCATCTTCTTTTGTAG                chr16:46836960-46836982 chr14:33243073-33243099  C16orf87 x AKAP6   known x known
-> 5706176_0_10403_3607_260/1                 GATGTCAATTTCCTTTTCCTGTTTCT AGATTCCTTTCCCATCTTCTTTTG                   chr16:46836957-46836982 chr14:33243076-33243099  C16orf87 x AKAP6   known x known
-> 4360877_1_10403_967_269/1                                  TCCTGTTTCT AGATTCCTTTCCCATCTTCTTTTGTAGACGTGTTTGCCAC   chr16:46836973-46836982 chr14:33243060-33243099  C16orf87 x AKAP6   known x known
-> 3324898_1_10403_728_270/2               ATAGACGTCAATTTCCTTTTCCTGTTTCT AGATTCCTTTCCCATCTGCTT                      chr16:46836954-46836982 chr14:33243079-33243099  C16orf87 x AKAP6   known x known
-> 26145375_0_10403_3593_288/1                              TTTCCTGTTTCT AGATTCCTTTCCCATCTTCTTTTGTAGACGTGTTTGCC     chr16:46836971-46836982 chr14:33243062-33243099  C16orf87 x AKAP6   known x known
-> 25932049_0_10403_3406_250/2                 ATGTCAATTTCCTTTTCCTGTTTCT AGATTCCTTTCCCATCTTCTTTTGT                  chr16:46836958-46836982 chr14:33243075-33243099  C16orf87 x AKAP6   known x known
-> 25573947_0_10403_3371_269/2                                 CCTGTTTCT AGATTCCTTTCCCATCTTCTTTTGTAGACGTGTTTGCCACT  chr16:46836974-46836982 chr14:33243059-33243099  C16orf87 x AKAP6   known x known
-> 23662023_0_10403_3618_257/1     AGGTTAGCATAGATGTCAATTTCCTTTTCCTGTTTCT AGATTCCTTTCCC                              chr16:46836946-46836982 chr14:33243087-33243099  C16orf87 x AKAP6   known x known
-> 22219661_1_10403_757_254/2                           TCCTTTTCCTGTTTCT AGATTCCTTTCCCATCTTCTTTTGTAGACGTGTT         chr16:46836967-46836982 chr14:33243066-33243099  C16orf87 x AKAP6   known x known
-> 19618109_0_10403_3442_206/2                         TTCCTTTTCCTGTTTCT AGATTCCTTTCCCATCTTCTTTTGTAGACGTGT          chr16:46836966-46836982 chr14:33243067-33243099  C16orf87 x AKAP6   known x known
-> 18094919_1_10403_721_278/2               TAGATGTCAATTTCCTTTTCCTGTTTCT AGATTCCTTTCCCATCTTCTTT                     chr16:46836955-46836982 chr14:33243078-33243099  C16orf87 x AKAP6   known x known
-> 17176082_1_10403_953_270/1                   TGTCAATTTCCTTTTCCTGTTTCT AGATTCCTTTCCCATCTTCGTTTGTA                 chr16:46836959-46836982 chr14:33243074-33243099  C16orf87 x AKAP6   known x known
-> 15183122_1_10403_956_277/1                      CAATTTCCTTTTCCTGTTTCT AGATTCCTTTCCCATCTTCTTTTGTAGAC              chr16:46836962-46836982 chr14:33243071-33243099  C16orf87 x AKAP6   known x known
-> 10112765_1_10403_943_264/1         TTAGCATAGATGTCAATTTCCTTTTCCTGTTTCT AGATTCCTTTCCCATC                           chr16:46836949-46836982 chr14:33243084-33243099  C16orf87 x AKAP6   known x known
# Total # of Junction Spanning Reads: 15

=cut
    

sub parse_fusion_result_file {
    my ($fusionhunter_out_file) = @_;

    my @fusions;


    my ($orientA, $orientB, $total_frag_support,
        $geneA, $chrA, $breakA,
        $geneB, $chrB, $breakB,
        $junction_frag_count);

    my $stage = 0;

    open (my $fh, $fusionhunter_out_file) or die "Error, cannot open file $fusionhunter_out_file";

    while (<$fh>) {
        #print;
        chomp;
        my @x = split(/\s+/);

        if (/^\#\s+Fusion:\s/) {

            unless ($stage == 0) {
                die "Error, stages out of order";
            }
            $stage = 1;

            # chr19:19256325-19314288+chr19:33685544-33716806[+-](52)
            /\[([\+\-])([\+\-])\]\((\d+)\)\s*$/ or die "Error, cannot extract fusion info from $_";
            $orientA = $1;
            $orientB = $2;
            $total_frag_support = $3;
            #print "Cond1\n";
        }
        elsif (/^\-\>/) {

            unless ($stage == 1 || $stage == 2) {
                die "Error, stages out of order";
            }
            $stage = 2;

            my $break_left_info = $x[4];
            my ($chr, $left_coord, $right_coord) = split(/[:-]/, $break_left_info);
            $breakA = ($orientA eq '+') ? $right_coord : $left_coord;
            $chr =~ s/chr//;
            $chrA = $chr;

            my $break_right_info = $x[5];
            ($chr, $left_coord, $right_coord) = split(/[:-]/, $break_right_info);
            $breakB = ($orientB eq '+') ? $left_coord : $right_coord;
            $chr =~ s/chr//;
            $chrB = $chr;

            $geneA = $x[6];
            $geneB = $x[8];

            $junction_frag_count++;

            #print "Cond2\n";
        }
        elsif (/# Total # of Junction Spanning Reads: (\d+)/) {


            if ($stage != 2) {
                die "Stages out of order";
            }


            my $num_junction_frags = $1;
            if ($num_junction_frags != $junction_frag_count) {
                die "Error, inconsistency of $num_junction_frags reported junction frags vs. counted $junction_frag_count for $geneA--$geneB";
            }

            # store the fusion
            my $struct = {

                geneA => $geneA,
                chrA => $chrA,
                coordA => $breakA,

                geneB => $geneB,
                chrB => $chrB,
                coordB => $breakB,

                span_reads => $total_frag_support,
                junc_reads => $junction_frag_count,
            };

            push (@fusions, $struct);

            # reinit
            for my $var ($orientA, $orientB, $total_frag_support,
                         $geneA, $chrA, $breakA,
                         $geneB, $chrB, $breakB,
                         $junction_frag_count) {
                undef $var;
            }
            $stage = 0;

        }
    }

    return(@fusions);
}


1; #EOM

