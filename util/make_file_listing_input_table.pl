#!/usr/bin/env perl

use strict;
use warnings;
use Carp;


## convert prog name tokens to names used in the data table.
my %converter = (CHIMERASCAN => 'ChimeraScan',
                 CHIMPIPE => 'ChimPipe',
                 DEFUSE => 'deFuse',
                 ERICSCRIPT => 'EricScript',
                 FUSIONHUNTER => 'FusionHunter',
                 FUSION_CATCHER_V0994e => 'FusionCatcher',
                 INFUSION_CF3 => 'InFusion',
                 JAFFA_ASSEMBLY => 'JAFFA-Assembly',
                 JAFFA_DIRECT => 'JAFFA-Direct',
                 JAFFA_HYBRID => 'JAFFA-Hybrid',
                 MAPSPLICE => 'MapSplice',
                 NFUSE => 'nFuse',
                 PRADA => 'PRADA',
                 SOAP_FUSE => 'SOAP-fuse',
                 'STAR_FUSION_GRCh37v19_FL3_v51b3df4' => 'STAR_FUSION_old',
                 TOPHAT_FUSION => 'TopHat-Fusion',
                 ARRIBA => ['ARRIBA', 'ARRIBA_hc'],
                 PIZZLY => 'PIZZLY',
                 STARCHIP => 'STARCHIP',
                 'STAR_FUSION_v1.5_hg19_Apr042019' => 'STAR_FUSION_v1.5',
                 STARCHIP_csm10 => 'STARChip_csm10',
                 TRINITY_FUSION_C_hg19 => 'TrinityFusion-C',
                 TRINITY_FUSION_UC_hg19 => 'TrinityFusion-UC',
                 TRINITY_FUSION_D_hg19 => 'TrinityFusion-D'
    );


while (<STDIN>) {
    chomp;
    my $filename = $_;

    if ($filename =~ m|/samples/([^/]+)/([^/]+)/|) {
        
        my $sample_name = $1;
        my $prog = $2;
        
        my $proper_progname = $converter{$prog} or die "Error, cannot find proper prog name for $prog as run on sample $sample_name";

        if (ref $proper_progname) {
            foreach my $progname_adj (@$proper_progname) {
                print join("\t", $sample_name, $progname_adj, $filename) . "\n";
            }
        }
        else {
            print join("\t", $sample_name, $proper_progname, $filename) . "\n";
        }
    }
    else {
        print STDERR "WARNING: couldn't decipher filename $filename as fusion result file\n";
    }
}


exit(0);


    
