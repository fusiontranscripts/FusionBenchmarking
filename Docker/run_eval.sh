#!/bin/bash

set -ev

cd /data

cp -r /usr/local/src/FusionBenchmarking FusionBenchmarkingWorkspace

PROGS_RESTRICT=`pwd`/FusionBenchmarkingWorkspace/progs_restrict.txt

cd FusionBenchmarkingWorkspace/cancer_cell_lines && ./runMe.sh ${PROGS_RESTRICT}

cd ../simulated_data && ./runMe.sh ${PROGS_RESTRICT}

echo done


