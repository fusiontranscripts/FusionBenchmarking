#!/bin/bash

set -ev

dirs=(sim_50 sim_101)

# run analyses separately for the sim_50 and sim_101 data
for dir in ${dirs[*]}
do
    cd $dir
    ./runMe.sh
    cd ../
done

####################################
# combine results into single figure

## allow rev
../benchmarking/plotters/plot_AUC_50_vs_101_boxplots.Rscript sim_50/__analyze_allow_reverse/all.AUC.dat sim_101/__analyze_allow_reverse/all.AUC.dat  allow_rev.combined.pdf

## allow rev & paralogs-ok
../benchmarking/plotters/plot_AUC_50_vs_101_boxplots.Rscript sim_50/__analyze_allow_rev_and_paralogs/all.AUC.dat sim_101/__analyze_allow_rev_and_paralogs/all.AUC.dat  allow_rev_and_paralogs.combined.pdf

           
           
