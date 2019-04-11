#!/bin/bash

set -ev


dirs=(simulated_data cancer_cell_lines runtime_analysis) 

for dir in ${dirs[*]}
do
    cd $dir
    ./cleanMe.sh
    cd ../
done

rm -rf ./figs_for_paper

