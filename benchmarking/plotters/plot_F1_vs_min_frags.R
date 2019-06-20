#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

args<-commandArgs(TRUE)

if (length(args) == 0) {
    stop("require param: min_X.results.scored.ROC")
}	

roc_file = args[1]

library(ggplot2)
library(dplyr)

data = read.table(roc_file, header=T)

p = data %>% filter(min_sum_frags <= 20) %>% ggplot(aes(x=min_sum_frags, y=F1, color=prog)) + geom_line()

pdf_filename = paste0(roc_file, ".F1_vs_minFrags.pdf")
pdf(pdf_filename, width=8)

plot(p)



