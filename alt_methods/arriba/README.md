# Arriba

## Singularity build:

singularity build arriba-1.1.0.simg docker://uhrigs/arriba:1.1.0

## Installation:

follow instructions here <https://arriba.readthedocs.io/en/latest/quickstart/>


	## for STAR-v2.7.0f
    wget https://github.com/suhrig/arriba/releases/download/v1.1.0/arriba_v1.1.0.tar.gz
    tar -xzf arriba_v1.1.0.tar.gz

    ./download_references.sh hs37d5+GENCODE19


now, using the singularity image so that the STAR versin will be consistent with it.

singularity exec -e -B `pwd`/references:/references SINGULARITY/arriba-1.1.0.simg download_references.sh hs37d5+GENCODE19

singularity exec -e -B /seq/RNASEQ -B `pwd`/output:/output -B `pwd`/../references:/references:ro -B `pwd`/reads_1.fq.gz:/read1.fastq.gz:ro -B `pwd`/reads_2.fq.gz:/read2.fastq.gz ../SINGULARITY/arriba-1.1.0.simg arriba.sh


```
+ STAR_INDEX_DIR=/references/STAR_index_hs37d5_GENCODE19
+ ANNOTATION_GTF=/references/GENCODE19.gtf
+ ASSEMBLY_FA=/references/hs37d5.fa
+ BLACKLIST_TSV=/references/blacklist_hg19_hs37d5_GRCh37_2018-11-04.tsv.gz
+ READ1=/read1.fastq.gz
+ READ2=/read2.fastq.gz
+ THREADS=8
++ dirname /arriba_v1.1.0/run_arriba.sh
+ BASE_DIR=/arriba_v1.1.0
+ STAR --runThreadN 8 --genomeDir /references/STAR_index_hs37d5_GENCODE19 --genomeLoad NoSharedMemory --readFilesIn /read1.fastq.gz /read2.fastq.gz --readFilesCommand zcat --outStd BAM_Unsorted --outSAMtype BAM Unsorted --outSAMunmapped Within --outBAMcompression 0 --outFilterMultimapNmax 1 --outFilterMismatchNmax 3 --chimSegmentMin 10 --chimOutType WithinBAM SoftClip --chimJunctionOverhangMin 10 --chimScoreMin 1 --chimScoreDropMax 30 --chimScoreJunctionNonGTAG 0 --chimScoreSeparation 1 --alignSJstitchMismatchNmax 5 -1 5 5 --chimSegmentReadGapMax 3
+ tee Aligned.out.bam
+ /arriba_v1.1.0/arriba -x /dev/stdin -o fusions.tsv -O fusions.discarded.tsv -a /references/hs37d5.fa -g /references/GENCODE19.gtf -b /references/blacklist_hg19_hs37d5_GRCh37_2018-11-04.tsv.gz -T -P
Loading annotation from '/references/GENCODE19.gtf'
Loading assembly from '/references/hs37d5.fa'
Reading chimeric alignments from '/dev/stdin' (total=2798)
Filtering multi-mappers and single mates (remaining=2798)
Detecting strandedness (no)
Annotating alignments
Filtering duplicates (remaining=2796)
Filtering mates which do not map to interesting contigs (1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y) (remaining=1181)
Estimating mate gap distributionWARNING: not enough chimeric reads to estimate mate gap distribution, using default values
Filtering read-through fragments with a distance <=10000bp (remaining=1147)
Filtering inconsistently clipped mates (remaining=1147)
Filtering breakpoints adjacent to homopolymers >=6nt (remaining=1146)
Filtering fragments with small insert size (remaining=1141)
Filtering alignments with long gaps (remaining=1141)
Filtering fragments with both mates in the same gene (remaining=1141)
Filtering fusions arising from hairpin structures (remaining=1134)
Filtering reads with a mismatch p-value <=0.01 (remaining=1117)
Filtering reads with low entropy (k-mer content >=60%) (remaining=1100)
Finding fusions and counting supporting reads (total=1062)
Merging adjacent fusion breakpoints (remaining=1061)
Estimating expected number of fusions by random chance (e-value)
Filtering fusions with both breakpoints in adjacent non-coding/intergenic regions (remaining=1053)
Filtering intragenic fusions with both breakpoints in exonic regions (remaining=1039)
Filtering fusions with <2 supporting reads (remaining=685)
Filtering fusions with an e-value >=0.3 (remaining=598)
Filtering fusions with both breakpoints in intronic/intergenic regions (remaining=598)
Filtering PCR fusions between genes with an expression above the 99.8% quantile (remaining=598)
Searching for fusions with spliced split reads (remaining=599)
Selecting best breakpoints from genes with multiple breakpoints (remaining=47)
Searching for fusions with >=4 spliced events (remaining=47)
Filtering blacklisted fusions in '/references/blacklist_hg19_hs37d5_GRCh37_2018-11-04.tsv.gz' (remaining=40)
Filtering fusions with anchors <=23nt (remaining=40)
Filtering end-to-end fusions with low support (remaining=36)
Filtering fusions with no coverage around the breakpoints (remaining=32)
Indexing gene sequences
Filtering genes with >=30% identity (remaining=31)
Re-aligning chimeric reads to filter fusions with >=80% mis-mappers (remaining=31)
Selecting best breakpoints from genes with multiple breakpoints (remaining=31)
Searching for additional isoforms (remaining=40)
Assigning confidence scores to events
Writing fusions to file 'fusions.tsv'
Writing discarded fusions to file 'fusions.discarded.tsv'
++ samtools --version-only
+ [[ 1.7+htslib-1.7-2 =~ ^1\. ]]
+ samtools sort -@ 8 -m 4G -T tmp -O bam Aligned.out.bam
[bam_sort_core] merging from 0 files and 8 in-memory blocks...
+ rm -f Aligned.out.bam
+ samtools index Aligned.sortedByCoord.out.bam
```




