#!/usr/bin/env perl

use strict;
use warnings;
use Carp;
use FindBin;
use Cwd;
use File::Basename;
use lib ("$FindBin::Bin/../PerlLib");
use Pipeliner;
use Process_cmd;


my $restricted_progs_file = $ARGV[0] || "";

unless ($ENV{FUSION_ANNOTATOR}) {

    if (-d "$ENV{HOME}/GITHUB/CTAT_FUSIONS/FusionAnnotator") {
        $ENV{FUSION_ANNOTATOR} = "~/GITHUB/CTAT_FUSIONS/FusionAnnotator";
    }
    else {
        die "Error, must set env var FUSION_ANNOTATOR to point to base dir of\n"
            . "      git clone https://github.com/FusionAnnotator/FusionAnnotator.git\n"
            . "      (after having installed it)  ";
    }
}

unless ($ENV{TRINITY_HOME}) {
    die "Error, must specify env var TRINITY_HOME to trinity base installation directory";
}


if (basename(cwd()) ne "cancer_cell_lines") {
    die "Error, must run this while in the cancer_cell_lines/ directory.";
}


my $benchmark_data_basedir = "$FindBin::Bin/..";
my $benchmark_toolkit_basedir = "$FindBin::Bin/../benchmarking";
my $fusion_annotator_basedir = $ENV{FUSION_ANNOTATOR};
my $trinity_home = $ENV{TRINITY_HOME};


main: {

    my $pipeliner = &init_pipeliner();
    
    ## create file listing
    my $cmd = "find ./samples -type f | $benchmark_data_basedir/util/make_file_listing_input_table.pl $restricted_progs_file > fusion_result_file_listing.dat";
    $pipeliner->add_commands(new Command($cmd, "fusion_file_listing.ok"));

    # collect predictions
    $cmd = "$benchmark_toolkit_basedir/collect_preds.pl fusion_result_file_listing.dat > preds.collected";
    $pipeliner->add_commands(new Command($cmd, "collect_preds.ok"));

    # map fusion predictions to gencode gene symbols based on identifiers or chromosomal coordinates.
    $cmd = "$benchmark_toolkit_basedir/map_gene_symbols_to_gencode.pl "
        . " preds.collected "
        . " $benchmark_data_basedir/resources/genes.coords.gz "
        . " $benchmark_data_basedir/resources/genes.aliases "
        . " > preds.collected.gencode_mapped ";

    $pipeliner->add_commands(new Command($cmd, "gencode_mapped.ok"));

    # annotate
    $cmd = "$fusion_annotator_basedir/FusionAnnotator --annotate preds.collected.gencode_mapped  -C 2 > preds.collected.gencode_mapped.wAnnot";
    $pipeliner->add_commands(new Command($cmd, "annotate_fusions.ok"));

    # filter HLA and mitochondrial features
    $cmd = "$benchmark_toolkit_basedir/filter_collected_preds.pl preds.collected.gencode_mapped.wAnnot > preds.collected.gencode_mapped.wAnnot.filt";
    $pipeliner->add_commands(new Command($cmd, "filter_fusion_annot.ok"));
    
    # generate and plot correlation matrix for predicted fusions by prog
    $cmd = "$benchmark_toolkit_basedir/fusion_preds_to_matrix.pl preds.collected.gencode_mapped.wAnnot.filt > preds.collected.gencode_mapped.wAnnot.filt.matrix";
    $pipeliner->add_commands(new Command($cmd, "pred_cor_matrix.ok"));

    $cmd = "$trinity_home/Analysis/DifferentialExpression/PtR  -m preds.collected.gencode_mapped.wAnnot.filt.matrix --binary --sample_cor_matrix --heatmap_colorscheme 'black,yellow' ";
    $pipeliner->add_commands(new Command($cmd, "pred_cor_matrix_plot.ok"));
    


    ## remove edgren set:
    $cmd = "bash -c 'set -eou pipefail; cat preds.collected.gencode_mapped.wAnnot.filt | egrep -v \"^(BT474|KPL4|MCF7|SKBR3)\" > preds.collected.gencode_mapped.wAnnot.filt.noEdgren'";
    $pipeliner->add_commands(new Command($cmd, "rmEdgren.ok"));
    
    ## run Venn-based accuracy analysis:

    $cmd = "$benchmark_toolkit_basedir/Venn_analysis_strategy.pl preds.collected.gencode_mapped.wAnnot.filt.noEdgren progs_select.txt 3 13";
    $pipeliner->add_commands(new Command($cmd, "venn_analysis.ok"));
    
    
    $pipeliner->run();
    
    exit(0);
    
    
}


####
sub init_pipeliner {
    
    my $pipeliner = new Pipeliner(-verbose => 2, -cmds_log => 'pipe.log');
    my $checkpoint_dir = cwd() . "/_checkpoints";
    unless (-d $checkpoint_dir) {
        mkdir $checkpoint_dir or die "Error, cannot mkdir $checkpoint_dir";
    }
    $pipeliner->set_checkpoint_dir($checkpoint_dir);

    return($pipeliner);
}

