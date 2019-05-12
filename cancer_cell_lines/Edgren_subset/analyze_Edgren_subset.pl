#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use File::Basename;
use lib ("$FindBin::Bin/../../PerlLib");
use Pipeliner;
use Process_cmd;
use Cwd;

if (basename(cwd()) ne "Edgren_subset") {
    die "Error, must run this while in the cancer_cell_lines/ directory.";
}


my $benchmark_data_basedir = "$FindBin::Bin/../..";
my $benchmark_toolkit_basedir = "$FindBin::Bin/../../benchmarking";


main: {

    my $pipeliner = &init_pipeliner();

    my $cmd = "$benchmark_toolkit_basedir/collected_preds_to_fusion_prog_support_listing.pl preds.collected.gencode_mapped.wAnnot.filt.edgren ../progs_select.txt  > preds.collected.gencode_mapped.wAnnot.filt.edgren.byProgAgree";
    $pipeliner->add_commands(new Command($cmd, "edgren.byProgAgree.ok"));
    
    ## need the unsure set defined. Basically, treat everything non-unique as unsure.
    $cmd = "$benchmark_toolkit_basedir/define_truth_n_unsure_set.pl preds.collected.gencode_mapped.wAnnot.filt.edgren.byProgAgree 1000";
    $pipeliner->add_commands(new Command($cmd, "define_min_agree.ok"));

    ## evaluate predictions:
    
    $cmd = "$benchmark_toolkit_basedir/fusion_preds_to_TP_FP_FN.pl "
         . " --truth_fusions edgren.truthset.raw "
         . " --fusion_preds preds.collected.gencode_mapped.wAnnot.filt.edgren "
         . " --allow_reverse_fusion "
         . " --allow_paralogs $benchmark_data_basedir/resources/paralog_clusters.dat "
         . " --unsure_fusions preds.collected.gencode_mapped.wAnnot.filt.edgren.byProgAgree.min_1000.unsure_set "
         . " > preds.collected.gencode_mapped.wAnnot.filt.edgren.scored ";

    $pipeliner->add_commands(new Command($cmd, "edgren.TP_FP_FN.ok"));
        
    my $roc_file = "preds.collected.gencode_mapped.wAnnot.filt.edgren.scored.ROC";
    
    $cmd = "$benchmark_toolkit_basedir/all_TP_FP_FN_to_ROC.pl preds.collected.gencode_mapped.wAnnot.filt.edgren.scored > $roc_file";
    $pipeliner->add_commands(new Command($cmd, "edgren.roc.ok"));
    
    # plot ROC
    $cmd = "$benchmark_toolkit_basedir/plotters/plot_ROC.Rscript $roc_file";
    $pipeliner->add_commands(new Command($cmd, "edgren.plot_roc.ok"));
    
    # plot F1
    $cmd = "$benchmark_toolkit_basedir/plotters/plot_F1_vs_min_frags.R $roc_file";
    $pipeliner->add_commands(new Command($cmd, "edgren.plot_F1_vs_min_frags.ok"));

    $cmd = "$benchmark_toolkit_basedir/plotters/plot_peak_F1_scatter.R $roc_file";
    $pipeliner->add_commands(new Command($cmd, "edgren.plot_peak_F1_scatter.ok"));

    # plot TP vs FP counts according to min frags per orog
    $cmd = "$benchmark_toolkit_basedir/plotters/plot_TP_FP_vs_minSum_per_prog.R $roc_file";
    $pipeliner->add_commands(new Command($cmd, "edgren.plot_TP_FP_vs_minFrags.ok"));
    
    
    ###################################
    # convert to Precision-Recall curve

    my $PR_file = "preds.collected.gencode_mapped.wAnnot.filt.edgren.scored.PR";
    
    $cmd = "$benchmark_toolkit_basedir/calc_PR.py --in_ROC $roc_file --min_read_support 3 --out_PR $PR_file | sort -k2,2gr | tee $PR_file.AUC";
    $pipeliner->add_commands(new Command($cmd, "edgren.pr.ok"));

    # plot PR curve
    $cmd = "$benchmark_toolkit_basedir/plotters/plotPRcurves.R $PR_file $PR_file.plot.pdf";
    $pipeliner->add_commands(new Command($cmd, "edgren.plot_pr.ok"));

    # plot AUC barplot
    $cmd = "$benchmark_toolkit_basedir/plotters/AUC_barplot.Rscript $PR_file.AUC";
    $pipeliner->add_commands(new Command($cmd, "edgren.plot_pr_auc_barplot.ok"));
    
    $pipeliner->run();

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
