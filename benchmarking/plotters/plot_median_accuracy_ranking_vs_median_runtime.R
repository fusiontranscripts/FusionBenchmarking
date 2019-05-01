#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

args<-commandArgs(TRUE)

if (length(args) != 2) {
    stop("require params: cancer_cell_lines/all.auc.rankings.dat all_progs_cancer/runtimes.txt")
}	

all_auc_rankings_file = args[1]
runtimes_file = args[2]

library(tidyverse)


auc_data = read.table(all_auc_rankings_file)

med_rank_data = auc_data %>% group_by(prog) %>% summarize(med_rank=median(rankval))

runtime_data = read.table(runtimes_file, header=T)

med_runtime_data = runtime_data %>% group_by(prog) %>% summarize(med_runtime=median(time_h, na.rm=T))

write.table(med_runtime_data, file='med_runtime_data.tsv', quote=F, sep='\t', row.names=F)
write.table(med_rank_data, file='med_rank_data.tsv', quote=F, sep='\t', row.names=F)


#p = data %>% group_by(prog) %>% filter(! is.na(F1)) %>% filter(F1 == max(F1)) %>% ggplot(aes(x=PPV, y=TPR, color=prog)) + geom_point()
#
#pdf_filename = paste0(roc_file, ".tpr_ppv_at_maxF1_scatter.pdf")
#pdf(pdf_filename)
#
#plot(p)



