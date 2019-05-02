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


if (basename(cwd()) !~ /^sim_(50|101)/) {
    die "Error, must run this while in the sim_50 or sim_101 directory.";
}


my $usage = "\n\n\tusage: $0  sim.truth.dat sim.fusion_TPM_values.dat [restrict_progs.file]\n\n";


my $sim_truth_set = $ARGV[0] or die $usage;
my $sim_fusion_TPM_values = $ARGV[1];
my $restrict_progs_file = $ARGV[2] || "";

$sim_truth_set = &ensure_full_path($sim_truth_set);
$sim_fusion_TPM_values = &ensure_full_path($sim_fusion_TPM_values) if ($sim_fusion_TPM_values);


my $benchmark_data_basedir = "$FindBin::Bin/..";
my $benchmark_toolkit_basedir = "$FindBin::Bin/../benchmarking";
my $fusion_annotator_basedir = $ENV{FUSION_ANNOTATOR};
my $trinity_home = $ENV{TRINITY_HOME};


main: {

    my $pipeliner = &init_pipeliner();
    
    ## create file listing
    my $cmd = "find ./samples -type f | $benchmark_data_basedir/util/make_file_listing_input_table.pl $restrict_progs_file > fusion_result_file_listing.dat";
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
    
    $pipeliner->run();
    
    ##################################
    ######  Scoring of fusions #######
    
    # score strictly
    &score_and_plot_replicates("preds.collected.gencode_mapped.wAnnot.filt", 
                               $sim_truth_set, 
                               $sim_fusion_TPM_values,
                               'analyze_strict', 
                               { allow_reverse_fusion => 0, allow_paralogs => 0 } );
    
    # score allow reverse fusion
    &score_and_plot_replicates("preds.collected.gencode_mapped.wAnnot.filt", 
                               $sim_truth_set, 
                               $sim_fusion_TPM_values,
                               'analyze_allow_reverse', 
                               { allow_reverse_fusion => 1, allow_paralogs => 0 } );

    # score allow reverse and allow for paralog-equivalence
    &score_and_plot_replicates("preds.collected.gencode_mapped.wAnnot.filt", 
                               $sim_truth_set, 
                               $sim_fusion_TPM_values,
                               'analyze_allow_rev_and_paralogs', 
                               { allow_reverse_fusion => 1, allow_paralogs => 1 } );
    



    ## Compare TP and FP before and after paralog-equiv

    $cmd = "$benchmark_toolkit_basedir/plotters/plot_before_vs_after_filt_TP_FP_compare.Rscript "
        . " __analyze_allow_reverse/all.scored.preds.ROC.best.dat "
        . " __analyze_allow_rev_and_paralogs/all.scored.preds.ROC.best.dat ";
    
    $pipeliner->add_commands(new Command($cmd, "before_vs_after_okPara.ok"));

    $pipeliner->run();
    

    

    
    exit(0);
    
    
}


####
sub score_and_plot_replicates {
    my ($input_file, $truth_set, $fusion_TPMs, $analysis_token, $analysis_settings_href, ) = @_;
    
    $input_file = &ensure_full_path($input_file); # the predictions
        
    my $base_workdir = cwd();

    my $workdir = "__" . "$analysis_token";

    unless (-d $workdir) {
        mkdir ($workdir) or die "Error, cannot mkdir $workdir";
    }
    chdir ($workdir) or die "Error, cannot cd to $workdir";
    
    
    my %sample_to_truth = &parse_truth_set($truth_set);

    my $preds_header = "";
    my %sample_to_fusion_preds = &parse_fusion_preds($input_file, \$preds_header); # updates hte preds_header value to header of file.
    

    ####################################
    ## Examine each replicate separately
    
    foreach my $sample_type (keys %sample_to_truth) {
        my $sample_checkpoint = "$sample_type.ok";
        if (! -e $sample_checkpoint) {
            &examine_sample($sample_type, $sample_to_truth{$sample_type}, $sample_to_fusion_preds{$sample_type}, $analysis_settings_href, $preds_header);
            &process_cmd("touch $sample_checkpoint");
        }
    }
    

    ######################################
    ## generate summary accuracy box plots
    
    my $pipeliner = &init_pipeliner();

    my $cmd = 'find . -regex ".*.scored.PR.AUC" -exec cat {} \\; > all.AUC.dat';
    $pipeliner->add_commands(new Command($cmd, "gather_AUC.ok"));
    
    $cmd = "$benchmark_toolkit_basedir/plotters/AUC_boxplot.from_single_summary_AUC_file.Rscript all.AUC.dat";
    $pipeliner->add_commands(new Command($cmd, "boxplot_rep_aucs.ok"));

    $cmd = 'find . -regex ".*.scored" -exec cat {} \\; > all.scored.preds';
    $pipeliner->add_commands(new Command($cmd, "gather_scores.ok"));

    $pipeliner->run();

    
    &ROC_and_PR("all.scored.preds");
        
    # examine sensitivity vs. expression level

    if ($fusion_TPMs) {
        $cmd = "$benchmark_toolkit_basedir/fusion_preds_sensitivity_vs_expr.avg_replicates.pl all.scored.preds $fusion_TPMs > all.scored.preds.sensitivity_vs_expr.dat";
        $pipeliner->add_commands(new Command($cmd, "sens_vs_expr.avg_reps.ok"));
        
        $cmd = "$trinity_home/Analysis/DifferentialExpression/PtR  "
            . " -m all.scored.preds.sensitivity_vs_expr.dat "
            . " --heatmap "
            . " --sample_clust none --gene_clust ward "
            . " --heatmap_colorscheme 'black,purple,yellow'";
        $pipeliner->add_commands(new Command($cmd, "sens_expr_heatmap.ok"));
        
        $pipeliner->run();
    }

    
    chdir $base_workdir or die "Error, cannot cd back to $base_workdir";
        
    return;
}
    
####
sub examine_sample {
    my ($sample_type, $sample_truth_href, $sample_to_fusion_preds_text, $analysis_settings_href, $preds_header) = @_;

    my $basedir = cwd();

    my $sample_dir = "$sample_type";
    unless (-d $sample_dir) {
        mkdir($sample_dir) or die "Error, cannot mkdir $sample_dir";
    }
    chdir $sample_dir or die "Error, cannot cd to $sample_dir";

    my $sample_TP_fusions_file = "TP.fusions.list";
    my $fusion_preds_file = "fusion_preds.txt";

    my $prep_inputs_checkpoint = "_prep.ok";
    
    if (! -e $prep_inputs_checkpoint) {
        {
            my @TP_fusions = keys %{$sample_truth_href};
            
            open (my $ofh, ">$sample_TP_fusions_file") or die "Error, cannot write to $sample_TP_fusions_file";
            print $ofh join("\n", @TP_fusions) . "\n";
            close $ofh;
        }
                
        {
            open (my $ofh, ">$fusion_preds_file") or die "Error, cannot write to $fusion_preds_file";
            print $ofh $preds_header;
            print $ofh $sample_to_fusion_preds_text;
            close $ofh;
        }
    
        &process_cmd("touch $prep_inputs_checkpoint");
    }

    ##################
    # score TP, FP, FN

    my $pipeliner = &init_pipeliner();
    
    my $cmd = "$benchmark_toolkit_basedir/fusion_preds_to_TP_FP_FN.pl --truth_fusions $sample_TP_fusions_file --fusion_preds $fusion_preds_file";
    
    if ($analysis_settings_href->{allow_reverse_fusion}) {
        $cmd .= " --allow_reverse_fusion ";
    }
    if ($analysis_settings_href->{allow_paralogs}) {
        $cmd .= " --allow_paralogs $benchmark_data_basedir/resources/paralog_clusters.dat ";
    }

    $cmd .= " > $fusion_preds_file.scored";

    $pipeliner->add_commands(new Command($cmd, "tp_fp_fn.ok"));
    
    $pipeliner->run();
    
    
    &ROC_and_PR("$fusion_preds_file.scored");
    

    chdir $basedir or die "Error, cannot cd back to $basedir";

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

    
    # plot F1
    $cmd = "$benchmark_toolkit_basedir/plotters/plot_F1_vs_min_frags.R $preds_scored.ROC";
    $pipeliner->add_commands(new Command($cmd, "plot_F1_vs_min_frags.ok"));

    $cmd = "$benchmark_toolkit_basedir/plotters/plot_peak_F1_scatter.R $preds_scored.ROC";
    $pipeliner->add_commands(new Command($cmd, "plot_peak_F1_scatter.ok"));
    
    # plot TP vs FP counts according to min frags per prog
    $cmd = "$benchmark_toolkit_basedir/plotters/plot_TP_FP_vs_minSum_per_prog.R $preds_scored.ROC";
    $pipeliner->add_commands(new Command($cmd, "sim_plot_TP_FP_vs_minFrags.ok"));
    
    
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

sub parse_truth_set {
    my ($tp_fusions_file) = @_;

    my %sample_to_truth;

    open(my $fh, $tp_fusions_file) or die "Error, cannot open file $tp_fusions_file";
    while (<$fh>) {
        chomp;
        my $full_fusion_name = $_;

        my ($sample_name, $core_fusion_name) = split(/\|/, $full_fusion_name);

        $sample_to_truth{$sample_name}->{$full_fusion_name} = 1;
    }
    close $fh;

    return(%sample_to_truth);

}


####
sub parse_fusion_preds {
    my ($preds_file, $preds_header_sref) = @_;

    my %sample_to_preds;
    {
        open (my $fh, $preds_file) or confess "Error, cannot open file $preds_file";
        my $header = <$fh>;
        unless ($header =~ /^sample/) {
            confess "Error, didn't parse expected header from file: $preds_file";
        }
        $$preds_header_sref = $header;
        
        while (<$fh>) {
            my $line = $_;
            my @x = split(/\t/);
            my $sample_name = $x[0];
            $sample_to_preds{$sample_name} .= $line;
        }
        close $fh;
    }

    return(%sample_to_preds);
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

