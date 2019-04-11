# STAR-Fusion_benchmarking_data

## Benchmarking fusion transcript detection

Both simulated and genuine RNA-Seq data were leveraged for benchmarking fusion detection accuracy. Each data set is described below as an extension to the methods described in the STAR-Fusion manuscript.

### Simulated reads

Simulated chimeric transcripts were generated using custom scripts, developed and released as the Fusion Simulator Toolkit (https://FusionSimulatorToolkit.github.io).

The simulated fusion transcript sequences are available at:
<https://data.broadinstitute.org/Trinity/STAR_FUSION_PAPER/SupplementaryData/sim_reads/fusion_transcript_sequences/>

The simulated 50 base paired-end reads are available at:
<https://data.broadinstitute.org/Trinity/STAR_FUSION_PAPER/SupplementaryData/sim_reads/sim_50_fastq/>

The simulated 101 base paired-end reads are available at:
<https://data.broadinstitute.org/Trinity/STAR_FUSION_PAPER/SupplementaryData/sim_reads/sim_101_fastq/>

All simulated reads were modeled based on genuine RNA-Seq data as outlined here:
<https://github.com/STAR-Fusion/STAR-Fusion_benchmarking_data/blob/master/simulated_data/SuppTable-sim_reads.csv>


### Cancer cell lines

Cancer cell line RNA-Seq data were obtained from the Cancer Cell Line Encyclopedia and supplemented with additional cell lines of interest, all identified at: <https://github.com/STAR-Fusion/STAR-Fusion_benchmarking_data/blob/master/cancer_cell_lines/SuppTable-cancer_cell_lines.csv> .

20M PE reads were randomly sampled from each data set using reservoir sampling (as implemented in: <https://github.com/trinityrnaseq/trinityrnaseq/blob/master/util/misc/fastQ_rand_subset.pl> ), and all reads evaluated as part of this study are available here:
<https://data.broadinstitute.org/Trinity/STAR_FUSION_PAPER/SupplementaryData/cancer_cell_lines/FASTQ/>


### Benchmarking scripts and computational methods

Fusion predictions from each of the methods on each of the samples are organized in the /samples subdirectory of the corresponding analysis type (ex. cancer_cell_lines/samples,  simulated_data/sim_50/samples, or simulated_data/sim_101/samples).
The following series of operations were taken to collect the list of fusion predictions from the sets of raw result files, score the predictions as true positives (TP), false positives (FP) or false negatives (FN), compute accuracy measures according to minimum evidence thresholds (generate ROC curves), compute precision recall (PR) curves and compute the area under the PR curve (AUC).

#### Utilities used in the benchmarking are provided at and referred to below as ${variable}:

*  ${FUSION_SIMULATOR) = https://github.com/FusionSimulatorToolkit/FusionSimulatorToolkit
*  ${FUSION_ANNOTATOR} = https://github.com/FusionAnnotator/FusionAnnotator
*  ${FUSION_BENCHMARK} = https://github.com/STAR-Fusion/STAR-Fusion_benchmarking_data


##### 1.  Organizing fusion prediction files

    find ./samples -type f | ${FUSION_BENCHMARK}/util/make_file_listing_input_table.pl > fusion_result_file_listing.dat

which generates a tab-delimited file listing the sample, program name, and path to the prediction output file.    For example:

    sim2_reads      InFusion        ./samples/sim2_reads/INFUSION_CF3/infusion_output/fusions.txt
    sim2_reads      JAFFA-Hybrid    ./samples/sim2_reads/JAFFA_HYBRID/jaffa_results.csv
    sim2_reads      PRADA   ./samples/sim2_reads/PRADA/prada_fusions/prada.fus.summary.txt
    sim3_reads      JAFFA-Direct    ./samples/sim3_reads/JAFFA_DIRECT/jaffa_results.csv
    sim3_reads      nFuse   ./samples/sim3_reads/NFUSE/rna.results.tsv
    sim3_reads      SOAP-fuse       ./samples/sim3_reads/SOAP_FUSE/final_fusion_genes/sample/sample.final.Fusion.specific.for.genes
    sim3_reads      ChimeraScan     ./samples/sim3_reads/CHIMERASCAN/chimeras.bedpe
    sim3_reads      FusionHunter    ./samples/sim3_reads/FUSIONHUNTER/FusionHunter.fusion
    sim3_reads      STAR-Fusion     ./samples/sim3_reads/STAR_FUSION_GRCh37v19_FL3_v51b3df4/star-fusion.fusion_candidates.final.abridged
    sim3_reads      TopHat-Fusion   ./samples/sim3_reads/TOPHAT_FUSION/tophatfusion_out/result.txt
    sim3_reads      FusionCatcher   ./samples/sim3_reads/FUSION_CATCHER_V0994e/FusionCatcher_outdir/final-list_candidate-fusion-genes.txt
    sim3_reads      ChimPipe        ./samples/sim3_reads/CHIMPIPE/chimericJunctions_chimpipe.txt
    sim3_reads      MapSplice       ./samples/sim3_reads/MAPSPLICE/fusions_well_annotated.txt
    sim3_reads      JAFFA-Assembly  ./samples/sim3_reads/JAFFA_ASSEMBLY/jaffa_results.csv
    sim3_reads      deFuse  ./samples/sim3_reads/DEFUSE/results.filtered.tsv
    sim3_reads      EricScript      ./samples/sim3_reads/ERICSCRIPT/ericscript_outdir/MyEric.results.filtered.tsv
    sim3_reads      InFusion        ./samples/sim3_reads/INFUSION_CF3/infusion_output/fusions.txt
    sim3_reads      JAFFA-Hybrid    ./samples/sim3_reads/JAFFA_HYBRID/jaffa_results.csv
    sim3_reads      PRADA   ./samples/sim3_reads/PRADA/prada_fusions/prada.fus.summary.txt
    sim1_reads      JAFFA-Direct    ./samples/sim1_reads/JAFFA_DIRECT/jaffa_results.csv
    sim1_reads      nFuse   ./samples/sim1_reads/NFUSE/rna.results.tsv
    sim1_reads      SOAP-fuse       ./samples/sim1_reads/SOAP_FUSE/final_fusion_genes/sample/sample.final.Fusion.specific.for.genes 
    ...


##### 2.  Collecting the fusion prediction results into a consistent format:

    ${FUSION_BENCHMARK}/benchmarking/collect_preds.pl fusion_result_file_listing.dat > preds.collected

with formatting like so:

    sample  prog    fusion  J       S
    sim2_reads      JAFFA-Direct    ENTPD6--VGF     216     1275
    sim2_reads      JAFFA-Direct    GYS2--AP000304.12       251     1225
    sim2_reads      JAFFA-Direct    TRNP1--GBA2     225     1184
    sim2_reads      JAFFA-Direct    POLDIP3--TNFSF14        181     1205
    ...

Here, J = number of junction (split) reads, and S = number of spanning fragments.

##### 3.  Mapping gene partners to Gencode v19 genes.

Many of the fusion prediction tools come with their own bundle of genome and annotation resources, which may contain gene symbols or coordinates that do not match up directly to the genome resources being used by the benchmarking analysis suite (Hg19 and Gencode v19).  In addition, it is sometimes the case that certain genes may overlap each other on the same genomic coordinates, and different programs may report different fusion partners based on similar if not identical fusion events.  To allow for more amenable comparisons among tools, we map gene fusion partners based on recognizable gene identifiers or based on Hg19 coordinate mappings to all overlapping genes in the Gencode v19 annotation set.  Any such overlapping gene is then allowed as an acceptable proxy for the 'true' fusion partner and scored as a TP.

Gene coordinates were extracted from the genome resource bundles provided with the different fusion predictors and provided along with the reference Gencode v19 coordinates at: <https://github.com/STAR-Fusion/STAR-Fusion_benchmarking_data/blob/master/resources/genes.coords>
For those genome bundles leveraging Hg38, coordinates were transformed to the Hg19 coordinate system using the UCSC LiftOver <https://genome-store.ucsc.edu/> utility.

In addition, Ensembl (ENSG-style) gene identifiers were converted to the more recognizable gene symbols (see file: <https://github.com/STAR-Fusion/STAR-Fusion_benchmarking_data/blob/master/resources/genes.aliases> ).


Fusion prediction gene mappings were performed like so:

    ${FUSION_SIMULATOR}/benchmarking/map_gene_symbols_to_gencode.pl \
       preds.collected \
       ${FUSION_BENCHMARK}/resources/genes.coords \
       ${FUSION_BENCHMARK}/resources/genes.aliases \
       > preds.collected.gencode_mapped

This adds the lists of Gencode genes that map to each of the predicted fusion partners A--B, provided as separate columns, one for gene A and another for gene B:

    sample  prog    fusion  J       S       mapped_gencode_A_gene_list      mapped_gencode_B_gene_list
    sim2_reads      JAFFA-Direct    ENTPD6--VGF     216     1275    ENTPD6,AL035252.1       VGF
    sim2_reads      JAFFA-Direct    GYS2--AP000304.12       251     1225    GYS2,C12orf39   ATP5O,AP000304.12,ITSN1,CRYZL1,LINC00649,DONSON,RN7SL740P
    sim2_reads      JAFFA-Direct    TRNP1--GBA2     225     1184    TRNP1   CREB3,RGP1,GBA2
    sim2_reads      JAFFA-Direct    POLDIP3--TNFSF14        181     1205    POLDIP3 TNFSF14
    sim2_reads      JAFFA-Direct    RORB--SLC44A3   216     1077    RORB,RP11-171A24.3      RP11-465K1.2,SLC44A3
    sim2_reads      JAFFA-Direct    GKN1--KCNG1     76      1210    GKN1    RP5-955M13.4,KCNG1
    sim2_reads      JAFFA-Direct    FPGT--NDUFS5    181     1077    FPGT-TNNI3K,TNNI3K,FPGT NDUFS5
    sim2_reads      JAFFA-Direct    ZCRB1--IGFBP7   204     1011    PPHLN1,ZCRB1    IGFBP7-AS1,POLR2B,IGFBP7,UBE2CP3
    ...


Below, we refer to the set of Gencode genes mapped to any gene X as gencode_mapped(X).


##### 4.  Adding annotation to fusion partners:

Our FusionAnnotator script was used to add basic meta data to the fusion predictions, primarily to identify genes of mitochondrial origin and to flag those predictions involving sequence-similar sequences (BLASTN, E<1e-3) and genes on the same chromosome and within 100kb are flagged as 'neighbors'.

    ${FUSION_ANNOTATOR}/FusionAnnotator --annotate preds.collected.gencode_mapped  -C 2 > preds.collected.gencode_mapped.wAnnot

##### 5.  Consistent filtering of all fusion predictions

All predictions regardless of prediction method were filtered consistently to remove any fusion pairs identified as sequence-similar, neighbors, involving genes of mitochondrial origin, or involving HLA genes (which often contain discordantly mapped reads due to the naturally high sequence diversity in those genomic regions).

##### 6.  Scoring of fusion predictions

The fusion predictions for each method and sample were scored accordingly:

*  TP:  fusion prediction A--B was scored as TP if fusion A--B is a member of the truth set, or gene A' is a member of gencode_mapped(A) and gene B' is included among gencode_mapped(B) and fusion prediction A'--B' is a member of the truth set.

*  FP: prediction is not recognized as a member of the truth set according to the above definition.

*  FN: a 'truth set' fusion prediction that was not identified as a TP.

We refer to the above mode of scoring as 'strict'.  In addition, we applied alternative scoring methods

* Allow reverse:  Gene prediction A--B is considered a TP if the truth set includes either A--B or B--A.

*  Allow paralogs:  Gene prediction A--B is additionally considered a TP if the truth set includes A'--B' where A' is identified as a putative paralog of A, and likewise for B and B'.


Results described in the STAR-Fusion manuscript for the simulated data are based on  'allow reverse' and 'allow reverse & allow paralogs', the latter providing for the most liberal assessment of fusion prediction accuracy.  For the cancer cell line accuracy, we report based on 'allow reverse', but results based on 'allow reverse & allow paralogs' are provided here as well.

The lists of paralogous gene clusters were computed using Markov clustering (<http://micans.org/mcl/>) as described (<https://github.com/STAR-Fusion/STAR-Fusion_benchmarking_data/blob/master/resources/notes> ), and with data provided as: <https://github.com/STAR-Fusion/STAR-Fusion_benchmarking_data/blob/master/resources/paralog_clusters.dat> .


###### Truth sets:

In the case of the simulated data set, the 'truth set' fusions are well defined, as they are constructed de novo and used as the substrates used for simulating corresponding RNA-Seq data.

For scoring the cancer cell line fusion data set, there is no absolute truth set. Instead, we operationally define the truth set as those fusions that are predicted as such by at least N methods.   For those fusions that are predicted by at least 1 method but less than (N-1) methods, it isn't clear whether they should be treated as FP; we include the option to simply ignore those fusions and not score them as TP or FP.


The fusion prediction scoring routine is implemented in the benchmarking suite as follows:

    ${FUSION_SIMULATOR}/benchmarking/fusion_preds_to_TP_FP_FN.pl

with usage:
 
    #################################################################################################
    #
    # Required:
    #
    #  --truth_fusions <string>   file containing a list of the true fusions.
    #
    #  --fusion_preds <string>    fusion predictions ranked accordingly.
    #
    #
    # Optional:
    #
    #  --unsure_fusions <string>   fusions where we're not sure if it's a TP or FP
    #
    #  --allow_reverse_fusion     if true fusion is A--B, allow for it to be reported as B--A
    #
    #  --allow_paralogs <string>  file containing tab-delimited list of paralog clusters
    #                             so if TP_A--TP_B  is a true fusion,
    #                               paraA1--paraB2  would be considered an ok proxy and scored as a TP.
    #
    ##################################################################################################



An example execution of the scoring script would be:

    ${FUSION_SIMULATOR}/benchmarking/fusion_preds_to_TP_FP_FN.pl \
        --truth_fusions sim_50.truth_set.dat \
        --fusion_preds preds.collected.gencode_mapped.wAnnot.filt \
        --allow_reverse_fusion \
        --allow_paralogs ${FUSION_BENCHMARK}/resources/paralog_clusters.dat \
        > preds.collected.gencode_mapped.wAnnot.filt.scored


The .scored output file is formatted like so:

    pred_result     sample  prog    fusion  J       S       mapped_gencode_A_gene_list      mapped_gencode_B_gene_list      explanation     selected_fusion
    TP      sim_adipose     nFuse   CAPS--CWC22     6144    8618    AC104532.2,RANBP3,CAPS,AC104532.4       CWC22   first encounter of TP nFuse,sim_adipose|CWC22--CAPS     sim_adipose|CWC22--CAPS
    TP      sim_adipose     nFuse   MLF1--WFDC5     6028    8623    MLF1    WFDC5   first encounter of TP nFuse,sim_adipose|WFDC5--MLF1     sim_adipose|WFDC5--MLF1
    TP      sim_adipose     nFuse   LRIT1--KIAA1377 5599    8596    LRIT1   KIAA1377,ANGPTL5        first encounter of TP nFuse,sim_adipose|LRIT1--KIAA1377 sim_adipose|LRIT1--KIAA1377
    TP      sim_adipose     nFuse   FLRT1--PROP1    4921    8536    FLRT1,RP11-21A7A.2,MACROD1,RP11-21A7A.3 PROP1   first encounter of TP nFuse,sim_adipose|PROP1--FLRT1    sim_adipose|PROP1--FLRT1
    NA-TP   sim_adipose     nFuse   MLF1--WFDC5     6023    146     MLF1    WFDC5   already scored nFuse,sim_adipose|WFDC5--MLF1 as TP      .
    FP      sim_adipose     nFuse   B2M--ICA1L      100     7       B2M     ICA1L,KRT8P15,AC098831.4        first encounter of FP fusion nFuse,sim_adipose|B2M--ICA1L       .
    FN      sim_adipose     nFuse   IGFBP6--ZNF302  0       0       .       .       prediction_lacking      .
    ...

If the same fusion prediction shows up multiple times (actually or 'effectively' - given allow-reverse or paralog equivalence options), it will only be scored as TP or FP once.   The other instances will show up as NA-TP or NA-FP and not contribute towards the accuracy assessment.

You'll also see two additional columns: 'explanation' and 'selected_fusion'. Explanation provides a short description of why the classification was assigned as observed, and 'selected_fusion' identifies the 'truth set' fusion that is being assigned here, which is particularly useful when the predicted fusion is being treated as a proxy for the truth set fusion.

##### 7.  ROC curves are computed based on TP, FP, FN, and minimum evidence thresholds.

ROC curves are computed like so:

    ${FUSION_SIMULATOR}/benchmarking/all_TP_FP_FN_to_ROC.pl \
       preds.collected.gencode_mapped.wAnnot.filt.scored \
       > preds.collected.gencode_mapped.wAnnot.filt.scored.ROC

and are formatted as follows:

    prog    min_sum_frags   TP      FP      FN      TPR     PPV     F1
    STAR-Fusion     2       1976    2       524     0.79    1       0.883
    STAR-Fusion     3       1939    2       561     0.78    1       0.876
    STAR-Fusion     4       1897    2       603     0.76    1       0.864 
    STAR-Fusion     5       1870    2       630     0.75    1       0.857
    STAR-Fusion     6       1841    2       659     0.74    1       0.851
    STAR-Fusion     7       1813    2       687     0.73    1       0.844
    STAR-Fusion     8       1784    2       716     0.71    1       0.830
    STAR-Fusion     9       1756    2       744     0.70    1       0.824
    STAR-Fusion     10      1726    2       774     0.69    1       0.817
    STAR-Fusion     11      1708    2       792     0.68    1       0.810
    STAR-Fusion     12      1690    2       810     0.68    1       0.810
    STAR-Fusion     13      1672    2       828     0.67    1       0.802
    STAR-Fusion     14      1656    2       844     0.66    1       0.795
    STAR-Fusion     15      1642    2       858     0.66    1       0.795
    STAR-Fusion     16      1625    2       875     0.65    1       0.788
    STAR-Fusion     17      1614    2       886     0.65    1       0.788
    STAR-Fusion     18      1595    1       905     0.64    1       0.780
    STAR-Fusion     19      1576    1       924     0.63    1       0.773
    STAR-Fusion     20      1558    1       942     0.62    1       0.765
    STAR-Fusion     21      1539    1       961     0.62    1       0.765
    STAR-Fusion     22      1523    1       977     0.61    1       0.758
    ...


##### 8.  Precision-Recall (PR) curves and PR-AUC

Precision-Recall (PR) curves and PR-AUC are computed from the ROC file like so:

     ${FUSION_SIMULATOR}/calc_PR.py \
         --in_ROC preds.collected.gencode_mapped.wAnnot.filt.scored.ROC \
         --out_PR preds.collected.gencode_mapped.wAnnot.filt.scored.PR \
            | sort -k2,2gr | tee preds.collected.gencode_mapped.wAnnot.filt.scored.PR.AUC



## Results from all accuracy assessments

All output files generated from the analysis assessments are included in the 'results' branch of the github repo:

<https://github.com/STAR-Fusion/STAR-Fusion_benchmarking_data/tree/results>


## Dockerization to enable reproducible analysis

All raw fusion prediction result files and code for performing the fusion accuracy assessment are bundled into a Docker image provided at:

<https://hub.docker.com/r/trinityctat/star_fusion_benchmarking_data/>


and the complete analysis can be recomputed by simply running the following command on a system that has Docker enabled:

    docker run --rm -v `pwd`:/data trinityctat/star_fusion_benchmarking_data

The above will copy the raw data to your current directory and then execute the analysis scripts to generate the accuracy output files and corresponding figures in pdf format.


## Questions, comments, etc?

   Contact Brian Haas

   bhaas (at) broadinstitute dot org


