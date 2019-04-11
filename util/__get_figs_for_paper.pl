#!/usr/bin/env perl

use strict;
use warnings;

my $usage = "usage: $0 repo_basedir\n";

my $basedir = $ARGV[0] or die $usage;

chdir $basedir or die "Error, cannot cd to $basedir";

# make the dir structure
my @dirs = ("sim", "cell_lines", "runtimes");
foreach my $dir (@dirs) {
    unless (-d $dir) {
        &process_cmd("mkdir -p figs_for_paper/$dir");
    }
}

my @targets_and_dests = ( 


    #####################
    # simulated data figs

    # Fig 2-a
    ["simulated_data/allow_rev.combined.pdf", 
     "figs_for_paper/sim/fig_2a.sim50_vs_101.boxplots.pdf"],

    # Fig 2-b, expression vs. sensitivity heatmap
    ["simulated_data/sim_101/__analyze_allow_reverse/all.scored.sensitivity_vs_expr.dat.genes_vs_samples_heatmap.pdf",
     "figs_for_paper/sim/fig_2b.sim_101.sens_vs_expr.heatmap.pdf"],

    # supp table 8 
    ["simulated_data/sim_101/__analyze_allow_reverse/all.scored.sensitivity_vs_expr.dat",
     "figs_for_paper/sim/supp_table_8.sim_101.sensitivity_vs_expression.tsv"],
    
    # Supp. Fig 1a
    ["simulated_data/sim_101/__analyze_allow_rev_and_paralogs/all.scored.ROC.best.dat.before_vs_after.pdf",
     "figs_for_paper/sim/supp_fig_1a.sim101.before_vs_after_paraEquiv.pdf"],

    # Supp. Fig 1b
    ["simulated_data/sim_50/__analyze_allow_rev_and_paralogs/all.scored.ROC.best.dat.before_vs_after.pdf",
     "figs_for_paper/sim/supp_fig_1b.sim50.before_vs_after_paraEquiv.pdf"],

    
    

    
    ####################
    # cancer cell lines

    # main fig 3a
    ["cancer_cell_lines/__min_4_agree/min_4.ignoreUnsure.results.scored.PR.AUC.barplot.pdf",
     "figs_for_paper/cell_lines/fig_3a.min_4.ignoreUnsure.PR_AUC_barplot.pdf"],

    # main fig 3b
    ["cancer_cell_lines/__min_4_agree/min_4.ignoreUnsure.results.scored.PR.plot.pdf",
     "figs_for_paper/cell_lines/fig_3b.min_4.ignoreUnsure.PR_curve.pdf"],

    # main fig 3c and 3d among others
    ["cancer_cell_lines/__min_4_agree/min_4.ignoreUnsure.results.scored.ROC.ROC_plot.pdf",
     "figs_for_paper/cell_lines/fig_3cd.min_4.ignoreUnsure.misc_accuracy_plots.pdf"],

    
    # Supp. Figure 2, correlation of fusion predictions among progs 
    ["cancer_cell_lines/preds.collected.gencode_mapped.wAnnot.filt.matrix.binary.sample_cor_matrix.pdf",
     "figs_for_paper/cell_lines/supp_fig_2.all_prediction_correlation_matrix.pdf"],
    
    
    # Supp. Figure 3, accuracy scoring collage of diff. truth set definitions. 
    ["cancer_cell_lines/all.auc.dat.pdf", 
     "figs_for_paper/cell_lines/supp_fig_3.min_4.accuracy_scoring_collage.pdf"],


    ## cancer cell lines ROC and AUC

    ["cancer_cell_lines/__min_4_agree/min_4.ignoreUnsure.results.scored.ROC",
     "figs_for_paper/cell_lines/supp_table_9.min_4.ignoreUnsure.ROC.tsv" ],

    ["cancer_cell_lines/__min_4_agree/min_4.ignoreUnsure.results.scored.PR.AUC",
     "figs_for_paper/cell_lines/supp_table_10.min_4.ignoreUnsure.AUC.tsv" ],

        
    ##################
    # runtime analysis

    # main fig 4: runtimes on cancer cell line data
    ["runtime_analysis/all_progs_cancer/runtimes.txt.boxplot.pdf", 
     "figs_for_paper/runtimes/fig_4.cell_line_runtimes.boxplot.pdf"],

        
    # supp. fig 4, starF runtimes w/ multithreading for star alignment 
    ["runtime_analysis/STAR_F_multicore/runtimes.txt.boxplot.pdf", 
     "figs_for_paper/runtimes/supp_fig_4.StarF_multithread_runtimes.boxplot.pdf"]
    
    
    );


foreach my $target_and_dest (@targets_and_dests) {

    my ($from, $to) = @$target_and_dest;

    &process_cmd("cp $from $to");

}


my @cmds_n_dests = (

    
    ## sim_50 ROC and AUC
    
    ["util/make_supp_ROC_table.pl simulated_data/sim_50/__analyze_allow_reverse/ sim_50",
     "figs_for_paper/sim/supp_table_4.sim_50.ROC.tsv"],
    
    ["util/make_supp_AUC_table.pl simulated_data/sim_50/__analyze_allow_reverse/ sim_50",
     "figs_for_paper/sim/supp_table_5.sim_50.AUC.tsv"],
    

    ## sim_101 ROC and AUC
    
    ["util/make_supp_ROC_table.pl simulated_data/sim_101/__analyze_allow_reverse/ sim_101",
     "figs_for_paper/sim/supp_table_6.sim_101.ROC.tsv"],

    ["util/make_supp_AUC_table.pl simulated_data/sim_101/__analyze_allow_reverse/ sim_101",
     "figs_for_paper/sim/supp_table_7.sim_101.AUC.tsv"],


    
    );


foreach my $cmd_n_dest (@cmds_n_dests) {
    my ($cmd, $dest) = @$cmd_n_dest;

    &process_cmd("$cmd > $dest");
}
    

exit(0);

####
sub process_cmd {
    my ($cmd) = @_;

    print "CMD: $cmd\n";
    my $ret = system($cmd);
    if ($ret) {
        die "Error, CMD: $cmd died with ret $ret";
    }
}

