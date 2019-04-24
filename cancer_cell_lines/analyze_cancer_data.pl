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
    my $cmd = "find ./samples -type f | $benchmark_data_basedir/util/make_file_listing_input_table.pl > fusion_result_file_listing.dat";
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
    
    # capture counts of progs agree:
    $cmd = "$benchmark_toolkit_basedir/collected_preds_to_fusion_prog_support_listing.pl preds.collected.gencode_mapped.wAnnot.filt progs_select.txt > preds.collected.gencode_mapped.wAnnot.filt.byProgAgree";
    $pipeliner->add_commands(new Command($cmd, "byProgAgree.ok"));
    
    $pipeliner->run();
    
    ##################################
    ######  Scoring of fusions #######

    #my @min_agree_truth = (3, 4, 5, 6);
    my @min_agree_truth = (2, 3, 4, 5);
    #my @min_agree_truth = (4);
    
    foreach my $min_agree (@min_agree_truth) {
        &score_and_plot("preds.collected.gencode_mapped.wAnnot.filt", "preds.collected.gencode_mapped.wAnnot.filt.byProgAgree", $min_agree);
    }


    ########################
    ## Summarize all results

    $cmd = "find __min_* -regex \".*PR.AUC\" | tee auc_files.list";
    $pipeliner->add_commands(new Command($cmd, "get_auc_files_list.ok"));

    $cmd = "$benchmark_data_basedir/util/capture_PR_AUC_for_plotting.pl auc_files.list > all.auc.dat";
    $pipeliner->add_commands(new Command($cmd, "all_auc_dat.ok"));

    $cmd = "$benchmark_data_basedir/util/plot_all_auc_barplots.Rscript";
    $pipeliner->add_commands(new Command($cmd, "plot_all_auc_barplots.ok"));

    $pipeliner->run();
    
    exit(0);
    
    
}


####
sub score_and_plot {
    my ($input_file, $prog_agree_listing, $min_agree) = @_;
    
    $input_file = &ensure_full_path($input_file);
    $prog_agree_listing = &ensure_full_path($prog_agree_listing);
        
    my $base_workdir = cwd();

    my $analysis_token = "min_${min_agree}_agree";
    
    my $workdir = "__" . "$analysis_token";

    unless (-d $workdir) {
        mkdir ($workdir) or die "Error, cannot mkdir $workdir";
    }
    chdir ($workdir) or die "Error, cannot cd to $workdir";

    my $pipeliner = &init_pipeliner();
    
    # define min agree set:
    my $cmd = "$benchmark_toolkit_basedir/define_truth_n_unsure_set.pl $prog_agree_listing $min_agree";
    $pipeliner->add_commands(new Command($cmd, "define_min${min_agree}_agree.ok"));

    $pipeliner->run();
    
    # creates two files:
    my $min_agree_truth_set = &ensure_full_path(basename($prog_agree_listing) . ".min_${min_agree}.truth_set");
    my $min_agree_unsure_set = &ensure_full_path(basename($prog_agree_listing) . ".min_${min_agree}.unsure_set");

    ## Examine accuracy by applying unsure and paralog-equiv options

    foreach my $settings_href ( { allow_paralogs => 0, unsure_fusions => undef },
                                { allow_paralogs => 1, unsure_fusions => undef },
                                { allow_paralogs => 0, unsure_fusions => $min_agree_unsure_set },
                                { allow_paralogs => 1, unsure_fusions => $min_agree_unsure_set } ) {

        &evaluate_predictions($min_agree, $input_file, $min_agree_truth_set, $settings_href);

    }

    chdir $base_workdir or die "Error, cannot cd back to $base_workdir";
        
    return;
}

####
sub evaluate_predictions {
    my ($min_agree, $input_file, $min_agree_truth_set, $analysis_settings_href) = @_;

    my $output_filename = "min_${min_agree}";
    my $checkpoint_token = "min_${min_agree}";
    {
        my @analysis_token_pts;
        if ($analysis_settings_href->{allow_paralogs}) {
            push (@analysis_token_pts, "okPara");
        }
        if ($analysis_settings_href->{unsure_fusions}) {
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
    
    my $cmd = "$benchmark_toolkit_basedir/fusion_preds_to_TP_FP_FN.pl --truth_fusions $min_agree_truth_set --fusion_preds $input_file";

    $cmd .= " --allow_reverse_fusion "; # always do this here. Sim data shows it's important for some progs.
    
    if ($analysis_settings_href->{allow_paralogs}) {
        $cmd .= " --allow_paralogs $benchmark_data_basedir/resources/paralog_clusters.dat ";
    }
    
    if ($analysis_settings_href->{unsure_fusions}) {
        $cmd .= " --unsure_fusions " . $analysis_settings_href->{unsure_fusions};
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


    # plot F1
    $cmd = "$benchmark_toolkit_basedir/plotters/plot_F1_vs_min_frags.R $output_filename.scored.ROC";
    $pipeliner->add_commands(new Command($cmd, "$checkpoint_token.plot_F1_vs_min_frags.ok"));

    $cmd = "$benchmark_toolkit_basedir/plotters/plot_peak_F1_scatter.R $output_filename.scored.ROC";
    $pipeliner->add_commands(new Command($cmd, "$checkpoint_token.plot_peak_F1_scatter.ok"));
    
    
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

    return;
    
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

