#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

args<-commandArgs(TRUE)

if (length(args) == 0) {
    stop("require param: min_X.results.scored.ROC")
}	

roc_file = args[1]

library(tidyverse)

data = read.table(roc_file, header=T)

max_TP = max(data$TP)

p = data %>% filter(min_sum_frags<20) %>% gather(key='TPFP', value='count', TP, FP) %>% ggplot(aes(x=min_sum_frags, y=count, color=TPFP)) + geom_point() + facet_wrap(~prog) + geom_hline(yintercept = max_TP) + ylim(0,1.5*max_TP)

pdf_filename = paste0(roc_file, ".TP_and_FP_counts_vs_minFrags_eaProg.pdf")
pdf(pdf_filename)

plot(p)



