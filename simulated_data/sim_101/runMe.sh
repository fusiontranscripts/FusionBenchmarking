#!/bin/bash

set -ev

if [ ! -d samples ]; then
    wget -r --no-parent https://data.broadinstitute.org/Trinity/CTAT_FUSIONTRANS_BENCHMARKING/on_simulated_data/sim_101/samples/
    find data.broadinstitute.org/|grep html | xargs -n1 rm -f
    mv data.broadinstitute.org/Trinity/CTAT_FUSIONTRANS_BENCHMARKING/on_simulated_data/sim_101/samples .
    rm -rf ./data.broadinstitute.org
fi


../analyze_simulated_data.pl sim_101.truth_set.dat sim_101.fusion_TPM_values.dat $*
