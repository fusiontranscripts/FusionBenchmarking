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


my $usage = "\n\n\tusage: $0 pred_files.txt truth_fusions.list ctat_genome_lib_dir\n\n";

my $pred_file_listing = $ARGV[0] or die $usage;
my $truth_fusions_file = $ARGV[1] or die $usage;
my $ctat_genome_lib = $ARGV[2] or die $usage;


$pred_file_listing = &ensure_full_path($pred_file_listing);
$truth_fusions_file = &ensure_full_path($truth_fusions_file);


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


my $benchmark_data_basedir = "$FindBin::Bin/..";
my $benchmark_toolkit_basedir = "$FindBin::Bin/../benchmarking";
my $fusion_annotator_basedir = $ENV{FUSION_ANNOTATOR};
my $trinity_home = $ENV{TRINITY_HOME};

main: {

    my $pipeliner = &init_pipeliner();

    # collect predictions
    my $cmd = "$benchmark_toolkit_basedir/collect_preds.pl $pred_file_listing > preds.collected";
    $pipeliner->add_commands(new Command($cmd, "collect_preds.ok"));

    # map fusion predictions to gencode gene symbols based on identifiers or chromosomal coordinates.
    $cmd = "$benchmark_toolkit_basedir/map_gene_symbols_to_gencode.pl "
        . " preds.collected "
        . " $benchmark_data_basedir/resources/genes.coords.gz "
        . " $benchmark_data_basedir/resources/genes.aliases "
        . " > preds.collected.gencode_mapped ";
    $pipeliner->add_commands(new Command($cmd, "gencode_mapped.ok"));

    # annotate
    $cmd = "$fusion_annotator_basedir/FusionAnnotator --annotate preds.collected.gencode_mapped  -C 2 --genome_lib_dir $ctat_genome_lib > preds.collected.gencode_mapped.wAnnot";
    $pipeliner->add_commands(new Command($cmd, "annotate_fusions.ok"));

    # filter HLA and mitochondrial features
    $cmd = "$benchmark_toolkit_basedir/filter_collected_preds.pl preds.collected.gencode_mapped.wAnnot > preds.collected.gencode_mapped.wAnnot.filt";
    $pipeliner->add_commands(new Command($cmd, "filter_fusion_annot.ok"));


    $pipeliner->run();
    

    ##################################
    ######  Scoring of fusions #######

    # score strictly
    &score_and_plot("preds.collected.gencode_mapped.wAnnot.filt",
                    $truth_fusions_file,
                    'analyze_strict',
                    { allow_reverse_fusion => 0, allow_paralogs => 0 } );

    # score allow reverse fusion
    &score_and_plot("preds.collected.gencode_mapped.wAnnot.filt",
                    $truth_fusions_file,
                    'analyze_allow_reverse',
                    { allow_reverse_fusion => 1, allow_paralogs => 0 } );
    
    # score allow reverse and allow for paralog-equivalence
    &score_and_plot("preds.collected.gencode_mapped.wAnnot.filt",
                    $truth_fusions_file,
                    'analyze_allow_rev_and_paralogs',
                    { allow_reverse_fusion => 1, allow_paralogs => 1 } );
    
    
}
    


####
sub score_and_plot {
    my ($input_file, $truth_set, $analysis_token, $analysis_settings_href) = @_;


    $input_file = &ensure_full_path($input_file);
    
    my $base_workdir = cwd();

    my $workdir = "__" . "$analysis_token";

    unless (-d $workdir) {
        mkdir ($workdir) or die "Error, cannot mkdir $workdir";
    }
    chdir ($workdir) or die "Error, cannot cd to $workdir";

    my $cmd = "$benchmark_toolkit_basedir/fusion_preds_to_TP_FP_FN.pl --truth_fusions $truth_set --fusion_preds $input_file";

    if ($analysis_settings_href->{allow_reverse_fusion}) {
        $cmd .= " --allow_reverse_fusion ";
    }
    if ($analysis_settings_href->{allow_paralogs}) {
        $cmd .= " --allow_paralogs $benchmark_data_basedir/resources/paralog_clusters.dat ";
    }

    $cmd .= " > fusion_preds_file.scored";

    
    my $pipeliner = new Pipeliner(-verbose => 2);
    $pipeliner->add_commands(new Command($cmd, "tp_fp_fn.ok"));

    $pipeliner->run();


    &ROC_and_PR("fusion_preds_file.scored");

    


    chdir $base_workdir or die "Error, cannot cd back to $base_workdir";

    return;
}


####
sub ROC_and_PR {
    my ($preds_scored) = @_;

    ## run analysis pipeline
    my $pipeliner = &init_pipeliner();

    ##############
    # generate ROC

    my $cmd = "$benchmark_toolkit_basedir/all_TP_FP_FN_to_ROC.pl $preds_scored > $preds_scored.ROC";
    $pipeliner->add_commands(new Command($cmd, "roc.ok"));

    # plot ROC
    $cmd = "$benchmark_toolkit_basedir/plotters/plot_ROC.Rscript $preds_scored.ROC";
    $pipeliner->add_commands(new Command($cmd, "plot_roc.ok"));

    ###################################
    # convert to Precision-Recall curve

    $cmd = "$benchmark_toolkit_basedir/calc_PR.py --in_ROC $preds_scored.ROC --out_PR $preds_scored.PR | sort -k2,2gr | tee $preds_scored.PR.AUC";
    $pipeliner->add_commands(new Command($cmd, "pr.ok"));

    # plot PR  curve
    $cmd = "$benchmark_toolkit_basedir/plotters/plotPRcurves.R $preds_scored.PR $preds_scored.PR.plot.pdf";
    $pipeliner->add_commands(new Command($cmd, "plot_pr.ok"));

    # plot AUC barplot
    $cmd = "$benchmark_toolkit_basedir/plotters/AUC_barplot.Rscript $preds_scored.PR.AUC";
    $pipeliner->add_commands(new Command($cmd, "plot_pr_auc_barplot.ok"));

    $pipeliner->run();

    return;

}

sub init_pipeliner {

    my $pipeliner = new Pipeliner(-verbose => 2, -cmds_log => 'pipe.log');
    my $checkpoint_dir = cwd() . "/_checkpoints";
    unless (-d $checkpoint_dir) {
        mkdir $checkpoint_dir or die "Error, cannot mkdir $checkpoint_dir";
    }
    $pipeliner->set_checkpoint_dir($checkpoint_dir);

    return($pipeliner);
}
