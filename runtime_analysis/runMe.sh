#!/bin/bash

set -ev

../util/boxplot_runtimes.Rscript ./STAR_F_multicore/runtimes.txt

../util/boxplot_runtimes.Rscript ./all_progs_cancer/runtimes.txt




