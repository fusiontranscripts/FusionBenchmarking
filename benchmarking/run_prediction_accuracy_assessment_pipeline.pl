#!/usr/bin/env perl

use strict;
use warnings;
use Carp;
use FindBin;
use Cwd;
use File::Basename;
use lib ($ENV{EUK_MODULES});
use Pipeliner;
use Process_cmd;
use Getopt::Long qw(:config posix_default no_ignore_case bundling pass_through);



my $usage = <<__EOUSAGE__;

#############################################################
#
#  --fusion_preds <string>    fusion predictions
#
#  --truth_fusions <string>   truth set
#
## Optional:
#
#  --unsure_fusions <string>   fusions where we're not sure if it's a TP or FP
#
#  --allow_reverse_fusion     if true fusion is A--B, allow for it to be reported as B--A
#
#  --allow_paralogs <string>  file containing tab-delimited list of paralog clusters
#                             so if TP_A--TP_B  is a true fusion,
#                               paraA1--paraB2  would be considered an ok proxy and scored as a TP.
#
##############################################################


__EOUSAGE__

    ;



my $help_flag;

my $input_file;
my $unsure_fusions_file;
my $allow_paralogs_flag = 0;
my $truth_fusions_file;


&GetOptions ( 'h' => \$help_flag,
              'fusion_preds=s' => \$input_file,
              'truth_fusions=s' => \$truth_fusions_file,
              'unsure_fusions=s' => \$unsure_fusions_file,
              'allow_paralogs' => \$allow_paralogs_flag,
    );



unless ($input_file && $truth_fusions_file) {
    die $usage;
}



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



my $benchmark_data_basedir = $ENV{FUSION_BENCHMARK_DATA} or die "Error, need env var FUSION_BENCHMARK_DATA";
my $benchmark_toolkit_basedir = $FindBin::Bin;
my $fusion_annotator_basedir = $ENV{FUSION_ANNOTATOR};
my $trinity_home = $ENV{TRINITY_HOME};


main: {

        
    ## create file listing

    ########

    my $output_filename = "preds";
    my $checkpoint_token = "preds";
    {
        my @analysis_token_pts;
        if ($allow_paralogs_flag) {
            push (@analysis_token_pts, "okPara");
        }
        if ($unsure_fusions_file) {
            push (@analysis_token_pts, "ignoreUnsure");
        }
        if (@analysis_token_pts) {
            my $analysis_token = join("_", @analysis_token_pts);
            $output_filename .= ".$analysis_token";
            $checkpoint_token .= ".$analysis_token";
        }
    }
    $output_filename .= ".results";
    
    ## run analysis pipeline
    my $pipeliner = &init_pipeliner();

    
    ##################
    # score TP, FP, FN
    
    my $cmd = "$benchmark_toolkit_basedir/fusion_preds_to_TP_FP_FN.pl --truth_fusions $truth_fusions_file --fusion_preds $input_file";

    $cmd .= " --allow_reverse_fusion "; # always do this here. Sim data shows it's important for some progs.
    
    if ($allow_paralogs_flag) {
        $cmd .= " --allow_paralogs $benchmark_data_basedir/resources/paralog_clusters.dat ";
    }
    
    if ($unsure_fusions_file) {
        $cmd .= " --unsure_fusions $unsure_fusions_file ";
    }

    $cmd .= " > $output_filename.scored";
    
    $pipeliner->add_commands(new Command($cmd, "$checkpoint_token.tp_fp_fn.ok"));

    ##############
    # generate ROC
    
    $cmd = "$benchmark_toolkit_basedir/all_TP_FP_FN_to_ROC.pl $output_filename.scored > $output_filename.scored.ROC"; 
    $pipeliner->add_commands(new Command($cmd, "$checkpoint_token.roc.ok"));
    
    # plot ROC
    $cmd = "$benchmark_toolkit_basedir/plotters/plot_ROC.Rscript $output_filename.scored.ROC";
    $pipeliner->add_commands(new Command($cmd, "$checkpoint_token.plot_roc.ok"));

    ###################################
    # convert to Precision-Recall curve
    
    $cmd = "$benchmark_toolkit_basedir/calc_PR.py --in_ROC $output_filename.scored.ROC --min_read_support 3 --out_PR $output_filename.scored.PR | sort -k2,2gr | tee $output_filename.scored.PR.AUC";
    $pipeliner->add_commands(new Command($cmd, "$checkpoint_token.pr.ok"));
    
    # plot PR curve
    $cmd = "$benchmark_toolkit_basedir/plotters/plotPRcurves.R $output_filename.scored.PR $output_filename.scored.PR.plot.pdf";
    $pipeliner->add_commands(new Command($cmd, "$checkpoint_token.plot_pr.ok"));
    
    # plot AUC barplot
    $cmd = "$benchmark_toolkit_basedir/plotters/AUC_barplot.Rscript $output_filename.scored.PR.AUC";
    $pipeliner->add_commands(new Command($cmd, "$checkpoint_token.plot_pr_auc_barplot.ok"));
    
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

