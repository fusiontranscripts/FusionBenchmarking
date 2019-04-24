#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

args<-commandArgs(TRUE)

if (length(args) == 0) {
    stop("require param: min_X.results.scored.ROC")
}	

roc_file = args[1]

library(tidyverse)

data = read.table(roc_file, header=T)

p = data %>% group_by(prog) %>% filter(F1 == max(F1)) %>% ggplot(aes(x=PPV, y=TPR, color=prog)) + geom_point()

pdf_filename = paste0(roc_file, ".tpr_ppv_at_maxF1_scatter.pdf")
pdf(pdf_filename)

plot(p)



