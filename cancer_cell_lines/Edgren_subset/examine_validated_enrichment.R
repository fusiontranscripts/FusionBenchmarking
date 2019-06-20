#!/usr/bin/env Rscript

library(ggplot2)
library(dplyr)
library(tidyr)

args<-commandArgs(TRUE)

if (length(args) != 2) {
    stop("require params: valid.fusions.txt  all_preds.scored")
}

valid_fusions_file = args[1] # edgren.truthset.raw
scored_preds = args[2] # preds.collected.gencode_mapped.wAnnot.filt.edgren.scored

progs_restrict = read.table("../progs_select.txt", header=F, stringsAsFactors=F)[,1]

valid_fusions = read.table(valid_fusions_file, header=F)[,1]

all_preds_data = read.table(scored_preds, header=T, sep="\t", row.names=NULL, stringsAsFactors=F);

all_preds_data = all_preds_data[all_preds_data$pred_result == "TP" | all_preds_data$pred_result == "FP", ]

## build new data table

TP_fusions = all_preds_data %>% filter(pred_result == "TP") %>% select(pred_result, sample, prog, J, S, fusion_name=selected_fusion)
FP_fusions = all_preds_data %>% filter(pred_result == "FP")  %>% mutate( fusion_name=sprintf("%s|%s", sample, fusion) ) %>% select(pred_result, sample, prog, J, S, fusion_name)

all_preds_data = rbind(TP_fusions, FP_fusions)

write.table(all_preds_data, "consolidated_edgren_predictions.dat", quote=F, sep="\t")

## remove preds not in the prog restricted list:
all_preds_data = all_preds_data[all_preds_data$prog %in% progs_restrict, ]

progs_found = unique(all_preds_data$prog)
missing = setdiff(progs_restrict, progs_found)
if (length(missing) > 0) {
    message("WARNING: missing representation by restricted progs: ", missing)
}

unique_fusion_preds = all_preds_data %>% select(fusion_name) %>% unique()
unique_fusion_preds = unique_fusion_preds$fusion_name

fusion_prog_counts = all_preds_data %>% group_by(fusion_name) %>% count()

all_preds_use = unique_fusion_preds

## limit sample space to all_preds_use


if (length(setdiff(valid_fusions, all_preds_use)) != 0) {
    message("WARNING: the following valid fusions are missing from predictions: ", paste(setdiff(valid_fusions, all_preds_use), collapse="\n"))
    valid_fusions = valid_fusions[valid_fusions %in% all_preds_use]
}

validated_minus = setdiff(all_preds_use, valid_fusions)

## removes: "BT474|LAMP1--MCF2"    "SKBR3|CCDC85C--SETD3"



num_total_progs = length(unique(all_preds_data$prog))

df_list = list()
for (min_progs_required in seq(1,num_total_progs)) {

    fusions_with_min_progs = fusion_prog_counts %>% filter(n >= min_progs_required)
    fusions_with_min_progs = fusions_with_min_progs$fusion_name

    predicted_plus = fusions_with_min_progs

    predicted_minus = setdiff(all_preds_use, predicted_plus)

    ## determine disjoint combo categories.
    validated_plus_predicted_plus = intersect(valid_fusions, predicted_plus)
    validated_plus_predicted_minus = intersect(valid_fusions, predicted_minus)

    validated_minus_predicted_plus = intersect(validated_minus, predicted_plus)
    validated_minus_predicted_minus = intersect(validated_minus, predicted_minus)

    df = data.frame(min_progs_required=min_progs_required,
                    Pp = length(predicted_plus),
                    Pm = length(predicted_minus),
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

write.table(summary_df, file=paste0(scored_preds, ".enrich_stats.tsv"), quote=F, sep="\t")



## make plots
pdf_filename = paste0(scored_preds, ".enrich_stats.pdf")

pdf(pdf_filename)

par(mfrow=c(2,1))

num_total_fusions = length(valid_fusions)

plot(summary_df$min_progs_required, summary_df$Vp_Pp, col='blue', main='Retaining Validated Fusions')
points(summary_df$min_progs_required, summary_df$enrich_score, col='orange', pch=2)
legend('topright', c('# validated fusions', 'enrichment score'), col=c('blue', 'orange'), pch=c(1,2))

plot(summary_df$min_progs_required, summary_df$valid_enrichment, main='enrichment ratio')

p = summary_df %>% ggplot() + geom_bar(mapping=aes(x=min_progs_required, y=Vp_Pp), stat="identity", fill='grey75') + geom_line(mapping=aes(x=min_progs_required, y=valid_enrichment*num_total_fusions), size=2, color='blue') + scale_y_continuous(name = '# validated fusions', sec.axis = sec_axis(~./num_total_fusions, name='% total pred. fusions', labels = function(b) { paste0(round(b * 100, 0), "%")}) ) + theme(axis.title.y.right = element_text(color = "blue"))

plot(p)

