#!/bin/bash

set -ev

./analyze_Edgren_subset.pl

../../benchmarking/Venn_analysis_strategy.pl preds.collected.gencode_mapped.wAnnot.filt.edgren ../progs_select.txt

