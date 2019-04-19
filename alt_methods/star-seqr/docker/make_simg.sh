#!/bin/bash

VERSION=0.6.7

singularity build star-seqr.v${VERSION}.simg docker://eagenomics/starseqr:$VERSION



