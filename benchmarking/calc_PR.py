#!/usr/bin/env python

import sys
import math
import argparse

# contributed by Bo Li, mod by bhaas

ntruth = 0


def main():

    parser = argparse.ArgumentParser(description="computes Precision-Recall Curve and AUC values", formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    
    parser.add_argument("--in_ROC", dest="in_ROC_file", type=str, default="", required=True, help="input ROC file")

    parser.add_argument("--out_PR", dest="out_PR_file", type=str, default="", required=True, help="output PR file")

    parser.add_argument("--min_read_support", dest="min_read_support", type=int, default=0, help="minimum read support for including data point in AUC computation")

    args = parser.parse_args()

    
    ntotal = 25000**2  # all possible gene pairs, rough approx.
    prog = ""
    ltp = lfp = 0
    auc = 0.0

    with open(args.in_ROC_file) as fin, open(args.out_PR_file, "w") as fout:
        # write header
        fout.write("{}\t{}\t{}\t{}\n".format('prog', 'recall', 'precision', 'actual'))
        next(fin) # skip header line
        for line in fin:
            fields = line.strip().split()

            min_frags = int(fields[1])
            if (min_frags < args.min_read_support):
                continue
            
            tp = int(fields[2])
            fp = int(fields[3])
            fn = int(fields[4])

            global ntruth
            ntruth = tp + fn

            if prog != fields[0]:
                # prog switch
                if prog != "":
                    # process last line of prev prog and report
                    auc += output(fout, prog, 0, 0, ltp, lfp)
                    print("{}\t{:.2f}".format(prog, auc))
                # first line of next prog, reinit vals
                prog = fields[0]
                ltp = ntruth
                lfp = ntotal - ntruth
                auc = output(fout, prog, ltp, lfp)

            # add to auc
            auc += output(fout, prog, tp, fp, ltp, lfp)
            ltp = tp
            lfp = fp

        if prog != "":
            # last line of file, process last prog results
            auc += output(fout, prog, 0, 0, ltp, lfp)
            print("{}\t{:.2f}".format(prog, auc))


    sys.exit(0)




def output(fout, prog, ntp, nfp, nltp = -1, nlfp = -1):
    """ return delta auc """

    dauc = 0.0
    if nltp < 0:
        recall = 1.0
        precision = ntp * 1.0 / (ntp + nfp)
        fout.write("{}\t{}\t{}\t0\n".format(prog, recall, precision))
    elif ntp == 0 and nfp == 0:
        assert nltp >= 0 and nlfp >= 0 and nltp + nlfp > 0
        lrecall = nltp * 1.0 / ntruth
        lprecision = nltp * 1.0 / (nltp + nlfp)
        recall = 0.0
        precision = lprecision
        if lrecall > 0.0:
            fout.write("{}\t{}\t{}\t0\n".format(prog, recall, precision))
            dauc = 0.5 * lrecall * lprecision
    else:
        recall = ntp * 1.0 / ntruth
        precision = ntp * 1.0 / (ntp + nfp)

        if nltp > ntp:
            lrecall = nltp * 1.0 / ntruth
            lprecision = nltp * 1.0 / (nltp + nlfp)
            
            rate = (nlfp - nfp) * 1.0 / (nltp - ntp)
            trecall = lrecall - 0.01
            x = nltp - ntp - 0.01 * ntruth
            tlrecall = lrecall
            tlprecision = lprecision
            while trecall > recall:
                trecall = (ntp + x) * 1.0 / ntruth
                tprecision = (ntp + x) * 1.0 / (ntp + x + nfp + rate * x)
                fout.write("{}\t{}\t{}\t0\n".format(prog, trecall, tprecision))
                dauc += 0.5 * (tlprecision + tprecision) * (tlrecall - trecall)

                tlrecall = trecall 
                tlprecision = tprecision
                trecall -= 0.01
                x -= 0.01 * ntruth

            dauc += 0.5 * (tlprecision + precision) * (tlrecall - recall)    

        fout.write("{}\t{}\t{}\t1\n".format(prog, recall, precision))
    
    return dauc




if __name__ == "__main__":
    main()
