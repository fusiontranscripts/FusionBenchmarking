#!/bin/bash

rm -f ./fusion_result_file_listing.dat ./preds.* ./pipe.log ./all* ./auc_files.list ./*.dat ./*.pdf
rm -rf ./_*

cd Edgren_subset && ./cleanMe.sh
