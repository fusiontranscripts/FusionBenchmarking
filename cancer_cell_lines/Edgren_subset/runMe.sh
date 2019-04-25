#!/bin/bash

set -ev


cat ../preds.collected.gencode_mapped.wAnnot.filt | egrep '^(sample|BT474|MCF7|KPL4|SKBR3)' > preds.collected.gencode_mapped.wAnnot.filt.edgren

./analyze_Edgren_subset.pl

../../benchmarking/Venn_analysis_strategy.pl preds.collected.gencode_mapped.wAnnot.filt.edgren ../progs_select.txt

