instructions found at: https://github.com/LosicLab/starchip/tree/master/example

## starchip setup
cp ~/CTAT_GENOMICS/genome_libs_StarF1.5/GRCh37_v19_CTAT_lib_Feb092018/ctat_genome_lib_build_dir/ref_genome.fa .

cp ~/CTAT_GENOMICS/genome_libs_StarF1.5/GRCh37_v19_CTAT_lib_Feb092018/ctat_genome_lib_build_dir/ref_annot.gtf .

singularity shell -e starchip.v1.3e.simg

/usr/local/src/starchip-1.3e/setup.sh ref_annot.gtf ref_genome.fa references/

cd references
wget http://hgdownload.soe.ucsc.edu/goldenPath/hg19/database/rmsk.txt.gz
gunzip rmsk.txt.gz
cut -f6-8 rmsk.txt > hg19.repeats.bed



## run test

singularity shell -e starchip.v1.3e.simg

- star alignment, using STAR v2.5.3a

STAR --genomeDir ../CTAT_GENOMICS/genome_libs_StarFpre-v1.3/GRCh37_gencode_v19_CTAT_lib_Nov012017/ctat_genome_lib_build_dir/ref_genome.fa.star.idx --readFilesIn ../GITHUB/CTAT_FUSIONS/STAR-Fusion/testing/reads_1.fq.gz ../GITHUB/CTAT_FUSIONS/STAR-Fusion/testing/reads_2.fq.gz --outReadsUnmapped Fastx --quantMode GeneCounts --chimSegmentMin 15 --chimJunctionOverhangMin 15 --outSAMstrandField intronMotif --readFilesCommand zcat --outSAMtype BAM Unsorted 

- run example

/usr/local/src/starchip-1.3e/starchip-fusions.pl  ladeda2 reference/example/Chimeric.out.junction  reference/hg19.parameters.txt  


