#!/bin/bash

set -ev


cat ../preds.collected.gencode_mapped.wAnnot.filt | egrep '^(sample|BT474|MCF7|KPL4|SKBR3)' > preds.collected.gencode_mapped.wAnnot.filt.edgren



## analyze accuracy
./analyze_Edgren_subset.pl


## examine enrichment for valid fusions among minProgs
./examine_validated_enrichment.R edgren.truthset.raw preds.collected.gencode_mapped.wAnnot.filt.edgren.scored


## examine min3 agree Venn

./eval_edgren_min_agree.consolidated.pl consolidated_edgren_predictions.dat 3 > edgren.min3

../../benchmarking/plotters/plot_upsetR.R edgren.min3




## run through standard analysis for curiosity sake
../../benchmarking/Venn_analysis_strategy.pl preds.collected.gencode_mapped.wAnnot.filt.edgren ../progs_select.txt 3 13
