#!/bin/bash

set -ev

if [ ! -d samples ]; then
    wget -r --no-parent https://data.broadinstitute.org/Trinity/CTAT_FUSIONTRANS_BENCHMARKING/on_cancer_cell_lines/samples/
    find data.broadinstitute.org/|grep html | xargs -n1 rm -f
    mv data.broadinstitute.org/Trinity/CTAT_FUSIONTRANS_BENCHMARKING/on_cancer_cell_lines/samples .
    rm -rf ./data.broadinstitute.org
fi



./analyze_cancer_data.pl


## Edgren subset study

cd Edgren_subset && ./runMe.sh

