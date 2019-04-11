#!/bin/bash

set -ev

cd /data

cp -r /usr/local/src/STAR-Fusion_benchmarking_data .

cd STAR-Fusion_benchmarking_data && ./runMe.sh


