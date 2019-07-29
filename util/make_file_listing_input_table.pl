#!/usr/bin/env perl

use strict;
use warnings;
use Carp;


my %restrict_progs;
if (@ARGV) {
    my $restrict_progs_file = $ARGV[0];
    open(my $fh, $restrict_progs_file) or die "Error, cannot open file: $restrict_progs_file";
    while(<$fh>) {
        chomp;
        unless (/\w/) { next; }
        my $progname = $_;
        $restrict_progs{$progname} = 1;
    }
    close $fh;
}
    

## convert prog name tokens to names used in the data table.
my %converter = (CHIMERASCAN => 'ChimeraScan',
                 CHIMPIPE => 'ChimPipe',
                 DEFUSE => 'deFuse',
                 ERICSCRIPT => 'EricScript',
                 FUSIONHUNTER => 'FusionHunter',
                 #FUSION_CATCHER_V0994e => 'FusionCatcher',
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
                 ARRIBA => ['ARRIBA', 'ARRIBA_hc'], ## scoring regular and the hc subset separately
                 PIZZLY => 'PIZZLY',
                 STARCHIP => 'STARCHIP',
                 'STAR_FUSION_v1.5_hg19_Apr042019' => 'STAR_FUSION_v1.5',
                 STARCHIP_csm10 => 'STARChip_csm10',
                 TRINITY_FUSION_C_hg19 => 'TrinityFusion-C',
                 TRINITY_FUSION_UC_hg19 => 'TrinityFusion-UC',
                 TRINITY_FUSION_D_hg19 => 'TrinityFusion-D',
                 STARSEQR => 'STARSEQR',
                 'STARSEQR_STAR-SEQR' => 'STARSEQR' 
    );


while (<STDIN>) {
    chomp;
    my $filename = $_;

    unless (-f $filename) {
        print STDERR "warning, $filename is not a file. Skipping...\n";
        next;
    }
    
    if ($filename =~ m|/samples/([^/]+)/([^/]+)/|) {
        
        my $sample_name = $1;
        my $prog = $2;

        if (%restrict_progs && ! exists $restrict_progs{$prog}) {
            print STDERR "make_file_listing_input_table::  - skipping $filename, not in restricted list.\n";
            next;
        }
        
        my $proper_progname = $converter{$prog};

        if ($proper_progname) {
            ## In case we have multiple ways of parsing the file and filtering data for different assessements.
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
            # keep original name
            print join("\t", $sample_name, $prog, $filename) . "\n";
        }
    }
    else {
        print STDERR "WARNING: not parsing filename as a target: $filename\n";
    }
}


exit(0);


    
