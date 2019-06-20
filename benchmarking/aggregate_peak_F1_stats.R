#!/usr/bin/env Rscript

library(ggplot2)
library(dplyr)
library(tidyr)

args<-commandArgs(TRUE)
if (length(args) != 3) {
    stop("require param: maxF1_file_suffix low_val high_val")  # example: okPara_ignoreUnsure.results.scored.ROC.tpr_ppv_at_maxF1.dat 3 13
}

file_suffix = args[1]
low_val = as.numeric(args[2])
high_val = as.numeric(args[3])


dfs_list = list()

for (minprogs in seq(low_val, high_val)) {
    dat_file = sprintf("__min_%d_agree/min_%d.%s", minprogs, minprogs, file_suffix)
    data = read.table(dat_file)

    data$min_progs_agree = minprogs

    dfs_list[[as.character(minprogs)]] <- data
}

all_data = do.call(rbind, dfs_list)

write.table(all_data, file=sprintf("%s.consolidated.dat", file_suffix), quote=F, sep="\t")

pdf(sprintf("%s.consolidated.scatters.pdf", file_suffix), height=5, width=11)

p = all_data %>% ggplot(aes(x=PPV, y=TPR, color=prog, shape=prog)) + geom_point() +  scale_shape_manual(values=rep(seq(0,25), 2)) + facet_wrap(~min_progs_agree)

plot(p)

dev.off()
