#!/bin/bash

set -ex

singularity exec -e -B `pwd`:/data trinityctat.fusionbenchmarking.simg /run_eval.sh
