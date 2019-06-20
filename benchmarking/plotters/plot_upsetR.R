#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

args<-commandArgs(TRUE)

if (length(args) == 0) {
    stop("require param: matrix")
}

prog_agree_matrix = args[1]

library(ggplot2)
library(dplyr)
library(tidyr)
library(UpSetR)


pdf_filename = sprintf("%s.UpSetR.pdf", prog_agree_matrix)
pdf(pdf_filename, width=11)

data = read.table(prog_agree_matrix, header=T)

upset(data, number.angles=90, nsets=1000, nintersects=1000)

dev.off()




