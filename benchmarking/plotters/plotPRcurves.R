#!/usr/bin/env Rscript

# contributed by Bo Li, mod by bhaas

argv = commandArgs(TRUE)
if (length(argv) != 2) {
   cat("Usage: Rscript plotPRcurves.R input.table output.pdf\n")
   q(status = 1)
}

lwd=1

plotPR = function(id, progs, data, colors) {
	idx = data[,1] == progs[id]
	if (id == 1) {
		plot(data[idx,2], data[idx,3], type = 'l', lwd = lwd, col = colors[id], lty = id, xlim = c(0, 1), ylim = c(0, 1), xlab = "Recall", ylab = "Precision")
	} else {
		par(new = T)
		plot(data[idx,2], data[idx,3], type = 'l', lwd = lwd, col = colors[id], lty = id, xlim = c(0, 1), ylim = c(0, 1), xlab = "", ylab = "")
	}
}

data = read.table(argv[1], header=T)
progs = levels(data[,1])
colors = rainbow(length(progs))

pdf(argv[2])
par(mar = c(5, 4, 8, 2) + 0.1, xpd = TRUE)
a = lapply(1:length(progs), plotPR, progs, data, colors)
legend(x = -0.06, y = 1.3, legend = progs, ncol = 3, lwd = lwd, col = colors, lty = 1:length(progs), cex = 0.54)
dev.off()
