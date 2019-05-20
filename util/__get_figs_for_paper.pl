#!/usr/bin/env perl

use strict;
use warnings;

my $usage = "usage: $0 repo_basedir\n";

my $basedir = $ARGV[0] or die $usage;

chdir $basedir or die "Error, cannot cd to $basedir";

# make the dir structure
unless (-d "figs_for_paper") {
    &process_cmd("mkdir -p figs_for_paper");
}


my @targets_and_dests = ( 
        
    ## Figure 2
    
    # Fig 2-a
    ["simulated_data/allow_rev.combined.pdf", 
     "figs_for_paper/fig_2a.sim50_vs_101.boxplots.pdf"],
    


    # Fig 2-b_top, expression vs. sensitivity heatmap PE 50
    ["simulated_data/sim_50/__analyze_allow_rev_and_paralogs/all.scored.preds.sensitivity_vs_expr.dat.genes_vs_samples_heatmap.pdf", 
     "figs_for_paper/fig_2b_top.sim_101.sens_vs_expr.heatmap.pdf"],
    
    # Fig 2-b_bottom, expression vs. sensitivity heatmap PE 101
    ["simulated_data/sim_101/__analyze_allow_rev_and_paralogs/all.scored.preds.sensitivity_vs_expr.dat.genes_vs_samples_heatmap.pdf",
     "figs_for_paper/fig_2b_top.sim_101.sens_vs_expr.heatmap.pdf"],
    
    
    ## Figure 3
    ["cancer_cell_lines/Edgren_subset/edgren.min3.UpSetR.pdf",
     "figs_for_paper/fig_3a.four_breast_cancer_cell_lines_UpSetR_plot_2nd_page.pdf"],
    
    ["cancer_cell_lines/Edgren_subset/preds.collected.gencode_mapped.wAnnot.filt.edgren.scored.enrich_stats.pdf",
     "figs_for_paper/fig_3b.valid_fusion_enrichment_2nd_page.pdf"],
    
    ## Figure 4
    ["cancer_cell_lines/all.auc.rankings.iu\=1.okp\=1.boxplot.pdf",
     "figs_for_paper/fig_4a_cancer_leaderboard_rankings.pdf"],
    
    ["cancer_cell_lines/__min_7_agree/min_7.okPara_ignoreUnsure.results.scored.ROC.tpr_ppv_at_maxF1_scatter.pdf",
     "figs_for_paper/fig_4d_peak_accuracy_min7progsagree.pdf"],
    
    
    
    ####################
    ## Supplementary Figures
    
    # supp fig 1
    ["simulated_data/sim_50/__analyze_allow_rev_and_paralogs/all.scored.preds.ROC.TP_and_FP_counts_vs_minFrags_eaProg.pdf",
     "figs_for_paper/supp_fig1.pe50_TP_FP_vs_minReads.pdf"],
    
    # supp fig 2
    ["simulated_data/sim_101/__analyze_allow_rev_and_paralogs/all.scored.preds.ROC.TP_and_FP_counts_vs_minFrags_eaProg.pdf",
     "figs_for_paper/supp_fig2.pe101_TP_FP_vs_minReads.pdf"],
    
    # supp fig 3a
    ["simulated_data/sim_50/__analyze_allow_rev_and_paralogs/all.scored.preds.ROC.tpr_ppv_at_maxF1_scatter.pdf",
     "figs_for_paper/supp_fig3a.pe50_max_F1_scatter.pdf"],
    
    # supp fig 3b
    ["simulated_data/sim_101/__analyze_allow_rev_and_paralogs/all.scored.preds.ROC.tpr_ppv_at_maxF1_scatter.pdf",
     "figs_for_paper/supp_fig3b.pe101_max_F1_scatter.pdf"],
    
    # supp fig 4
    ["cancer_cell_lines/okPara_ignoreUnsure.results.scored.ROC.tpr_ppv_at_maxF1.dat.consolidated.scatters.pdf",
     "figs_for_paper/supp_fig4.cancer_maxF1_ea_truthset.pdf"],

    # supp fig 5
    ["simulated_data/sim_101/__analyze_allow_rev_and_paralogs/all.scored.preds.ROC.best.dat.before_vs_after.pdf",
     "figs_for_paper/supp_fig5.before_vs_after_paralog_equiv_pe101.pdf"],
    
    # supp fig 6
    ["cancer_cell_lines/preds.collected.gencode_mapped.wAnnot.filt.matrix.binary.sample_cor_matrix.pdf",
     "figs_for_paper/supp_fig6.cancer_correlated_preds.pdf"],

    # supp fig 7
    ["cancer_cell_lines/all.auc.rankings_per_prog_adj.boxplot.pdf",
     "figs_for_paper/supp_fig7.effect_iu_okp_on_cancer_ranking_dist.pdf"],
    
    # supp fig 8
    ["cancer_cell_lines/all.auc.rankings.iu\=1.okp\=0.boxplot.pdf",
     "figs_for_paper/supp_fig8.cancer_rankings_equiv_para_off.pdf"],
    
    
    ############################
    ## Supplementary data files
    
    # supp table 1
    ["simulated_data/sim_50/preds.collected.gencode_mapped.wAnnot.filt",
     "figs_for_paper/supp_table1.pe50_fusion_filtered_preds.tsv"],
    
    # supp table 2
    ["simulated_data/sim_101/preds.collected.gencode_mapped.wAnnot.filt",
     "figs_for_paper/supp_table1.pe101_fusion_filtered_preds.tsv"],
    
    # supp table 4
    ["cancer_cell_lines/preds.collected.gencode_mapped.wAnnot.filt",
     "figs_for_paper/supp_table4.cancer_fusion_filtered_preds.tsv"],

    );    


    
foreach my $target_and_dest (@targets_and_dests) {

    my ($from, $to) = @$target_and_dest;

    &process_cmd("cp $from $to");

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

