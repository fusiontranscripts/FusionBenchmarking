#!/bin/bash

set -ev

## download the starchip reference bundle and unpack
## replace /seq/RNASEQ/TOOLS/STARCHIP/reference
## replace /seq/RNASEQ/TOOLS/STARCHIP/SINGULARITY/starchip.v1.3e.simg  with your location for the simg.


singularity exec -e -B `pwd` \
    -B /seq/RNASEQ/TOOLS/STARCHIP/reference:/usr/local/src/reference \
       /seq/RNASEQ/TOOLS/STARCHIP/SINGULARITY/starchip.v1.3e.simg \
       /usr/local/bin/starchip_wrapper.pl \
            --left_fq test_data/reads_1.fq.gz \
            --right_fq test_data/reads_2.fq.gz \
            --starchip_parameters_file /usr/local/src/reference/hg19.parameters \
            --output_dir `pwd`/test_outdir

