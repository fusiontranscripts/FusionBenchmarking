#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

args<-commandArgs(TRUE)

if (length(args) == 0) {
    stop("require param: min_X.results.scored.ROC")
}

roc_file = args[1]

library(tidyverse)

data = read.table(roc_file, header=T)


peak_F1_data = data %>% group_by(prog) %>% filter(! is.na(F1)) %>% filter(F1 == max(F1)) %>% arrange(desc(F1))

p = peak_F1_data %>% ggplot(aes(x=PPV, y=TPR, color=prog, shape=prog)) + geom_point() + scale_shape_manual(values=rep(seq(0,25), 2))

pdf_filename = paste0(roc_file, ".tpr_ppv_at_maxF1_scatter.pdf")
pdf(pdf_filename, width=9, height=4)

plot(p)


peak_F1_dat_file = paste0(roc_file, ".tpr_ppv_at_maxF1.dat")
write.table(peak_F1_data, file=peak_F1_dat_file, quote=F, sep="\t")

