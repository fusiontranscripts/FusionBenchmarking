#!/bin/bash

VERSION=`cat VERSION.txt`

singularity build starchip.v${VERSION}.simg docker://fusiontranscripts/starchip:$VERSION
