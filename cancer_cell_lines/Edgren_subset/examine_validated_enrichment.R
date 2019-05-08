#!/usr/bin/env Rscript

library('tidyverse')

args<-commandArgs(TRUE)

if (length(args) != 3) {
    stop("require params: valid.fusions.txt  preds.byProgAgree  all_preds")
}

valid_fusions_file = args[1]
preds_by_prog_agree_file = args[2]
all_preds_file = args[3]

valid_fusions = read.table(valid_fusions_file, header=F)[,1]

progs_agree_data = read.table(preds_by_prog_agree_file, header=F)
colnames(progs_agree_data) = c('fusion', 'proglist', 'progcount')

all_preds_data = read.table(all_preds_file, header=F, row.names=NULL, stringsAsFactors=F, skip=1);
colnames(all_preds_data) = c('sample', 'prog', 'fusion', 'J', 'S', 'mapped_gencode_A_gene_list', 'mapped_gencode_B_gene_list', 'annots')

all_preds_data$full_fusion_name = paste(all_preds_data$sample, "|", all_preds_data$fusion, sep="")

min_sum_counts = 5 # 95%tile of validated fusion predictions called here.

all_preds_use = unique(all_preds_data[ (all_preds_data$J + all_preds_data$S >= min_sum_counts),]$full_fusion_name)



## limit sample space to all_preds_use
valid_fusions = valid_fusions[valid_fusions %in% all_preds_use]
progs_agree_data = progs_agree_data[ progs_agree_data$fusion %in% all_preds_use, ]

## removes: "BT474|LAMP1--MCF2"    "SKBR3|CCDC85C--SETD3"

validated_minus = setdiff(all_preds_use, valid_fusions)

df_list = list()
for (min_progs_required in seq(1,15)) {

    fusions_with_min_progs = unique(progs_agree_data[progs_agree_data$progcount >= min_progs_required, ]$fusion)

    predicted_minus = setdiff(all_preds_use, fusions_with_min_progs)


    ## determine disjoint combo categories.
    validated_plus_predicted_plus = intersect(valid_fusions, fusions_with_min_progs)
    validated_plus_predicted_minus = intersect(valid_fusions, predicted_minus)

    validated_minus_predicted_plus = intersect(validated_minus, fusions_with_min_progs)
    validated_minus_predicted_minus = intersect(validated_minus, predicted_minus)

    df = data.frame(min_progs_required=min_progs_required,
                    Vp_Pp = length(validated_plus_predicted_plus),
                    Vp_Pm = length(validated_plus_predicted_minus),
                    Vm_Pp = length(validated_minus_predicted_plus),
                    Vm_Pm = length(validated_minus_predicted_minus) )

    df_list[[ length(df_list) + 1 ]] = df
}

summary_df = do.call(rbind, df_list)
summary_df$rowsum = rowSums(summary_df[,-1])



##
## Contigency table:
#'
#'                          Predicted
#'                     Yes(+)      No(-)
#'
#'             Yes(+)  Vp_Pp   |   Vp_Pm
#'   Validated         -----------------
#'             No(-)   Vm_Pp   |   Vm_Pm
#'
#' Note, p=plus, m=minus
#'



stat.test = do.call(rbind, apply(summary_df, 1, function(x) {
    #print(x)
    ##test = fisher.test(rbind(c(x[['Vp_Pp']]+1, x[['Vp_Pm']]+1), c(x[['Vm_Pp']]+1, x[['Vm_Pm']]+1)), alternative='greater')
    test = fisher.test(rbind(c(x[['Vp_Pp']], x[['Vp_Pm']]), c(x[['Vm_Pp']], x[['Vm_Pm']])), alternative='greater')
    data.frame(pvalue=test$p.value, oddsratio=test$estimate)
}) )

summary_df$pvalue = stat.test$pvalue
summary_df$oddsratio = stat.test$oddsratio

summary_df$valid_enrichment = summary_df$Vp_Pp /  (summary_df$Vp_Pp + summary_df$Vm_Pp)

summary_df$enrich_score = summary_df$Vp_Pp * summary_df$valid_enrichment

summary_df$PpVp_odds = (  (summary_df$Vp_Pp +1) / (summary_df$Vm_Pp + 1) )

summary_df$PmVp_odds = (  (summary_df$Vp_Pm +1) / (summary_df$Vm_Pm + 1) )

summary_df$Pxvp_oddsratio = summary_df$PpVp_odds / summary_df$PmVp_odds

print(summary_df)

write.table(summary_df, file=paste0(preds_by_prog_agree_file, ".enrich_stats.tsv"), quote=F, sep="\t")



## make plots
pdf_filename = paste0(preds_by_prog_agree_file, ".enrich_stats.pdf")

pdf(pdf_filename)

par(mfrow=c(2,1))

plot(summary_df$min_progs_required, summary_df$Vp_Pp, col='blue', main='Retaining Validated Fusions')
points(summary_df$min_progs_required, summary_df$enrich_score, col='orange', pch=2)
legend('topright', c('# validated fusions', 'enrichment score'), col=c('blue', 'orange'), pch=c(1,2))

plot(summary_df$min_progs_required, summary_df$valid_enrichment, main='enrichment ratio')

p = summary_df %>% ggplot() + geom_bar(mapping=aes(x=min_progs_required, y=Vp_Pp), stat="identity", fill='grey75') + geom_line(mapping=aes(x=min_progs_required, y=valid_enrichment*37), size=2, color='blue') + scale_y_continuous(name = '# validated fusions', sec.axis = sec_axis(~./37, name='% total pred. fusions', labels = function(b) { paste0(round(b * 100, 0), "%")}) ) + theme(axis.title.y.right = element_text(color = "blue"))

plot(p)

