library(cluster)
library(Biobase)
library(qvalue)
library(fastcluster)
options(stringsAsFactors = FALSE)
NO_REUSE = F

# try to reuse earlier-loaded data if possible
if (file.exists("preds.collected.gencode_mapped.wAnnot.filt.matrix.RData") && ! NO_REUSE) {
    print('RESTORING DATA FROM EARLIER ANALYSIS')
    load("preds.collected.gencode_mapped.wAnnot.filt.matrix.RData")
} else {
    print('Reading matrix file.')
    primary_data = read.table("preds.collected.gencode_mapped.wAnnot.filt.matrix", header=T, com='', row.names=1, check.names=F, sep='\t')
    primary_data = as.matrix(primary_data)
}
source("/usr/local/src/trinityrnaseq/Analysis/DifferentialExpression/R/heatmap.3.R")
source("/usr/local/src/trinityrnaseq/Analysis/DifferentialExpression/R/misc_rnaseq_funcs.R")
source("/usr/local/src/trinityrnaseq/Analysis/DifferentialExpression/R/pairs3.R")
source("/usr/local/src/trinityrnaseq/Analysis/DifferentialExpression/R/vioplot2.R")
data = primary_data
myheatcol = colorpanel(75, 'black','yellow')
sample_types = colnames(data)
nsamples = length(sample_types)
sample_colors = rainbow(nsamples)
sample_type_list = list()
for (i in 1:nsamples) {
    sample_type_list[[sample_types[i]]] = sample_types[i]
}
sample_factoring = colnames(data)
for (i in 1:nsamples) {
    sample_type = sample_types[i]
    replicates_want = sample_type_list[[sample_type]]
    sample_factoring[ colnames(data) %in% replicates_want ] = sample_type
}
initial_matrix = data # store before doing various data transformations
data[data<0] = 0; data[data>0] = 1;
sample_factoring = colnames(data)
for (i in 1:nsamples) {
    sample_type = sample_types[i]
    replicates_want = sample_type_list[[sample_type]]
    sample_factoring[ colnames(data) %in% replicates_want ] = sample_type
}
sampleAnnotations = matrix(ncol=ncol(data),nrow=nsamples)
for (i in 1:nsamples) {
  sampleAnnotations[i,] = colnames(data) %in% sample_type_list[[sample_types[i]]]
}
sampleAnnotations = apply(sampleAnnotations, 1:2, function(x) as.logical(x))
sampleAnnotations = sample_matrix_to_color_assignments(sampleAnnotations, col=sample_colors)
rownames(sampleAnnotations) = as.vector(sample_types)
colnames(sampleAnnotations) = colnames(data)
data = as.matrix(data) # convert to matrix
write.table(data, file="preds.collected.gencode_mapped.wAnnot.filt.matrix.binary.dat", quote=F, sep='	');
if (nrow(data) < 2) { stop("

**** Sorry, at least two rows are required for this matrix.

");}
if (ncol(data) < 2) { stop("

**** Sorry, at least two columns are required for this matrix.

");}
sample_cor = cor(data, method='pearson', use='pairwise.complete.obs')
write.table(sample_cor, file="preds.collected.gencode_mapped.wAnnot.filt.matrix.binary.sample_cor.dat", quote=F, sep='	')
sample_dist = dist(t(data), method='euclidean')
hc_samples = hclust(sample_dist, method='complete')
pdf("preds.collected.gencode_mapped.wAnnot.filt.matrix.binary.sample_cor_matrix.pdf")
sample_cor_for_plot = sample_cor
heatmap.3(sample_cor_for_plot, dendrogram='both', Rowv=as.dendrogram(hc_samples), Colv=as.dendrogram(hc_samples), col = myheatcol, scale='none', symm=TRUE, key=TRUE,density.info='none', trace='none', symkey=FALSE, symbreaks=F, margins=c(10,10), cexCol=1, cexRow=1, cex.main=0.75, main=paste("sample correlation matrix
", "preds.collected.gencode_mapped.wAnnot.filt.matrix.binary") )
dev.off()
gene_cor = NULL
