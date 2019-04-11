#!/bin/bash

dirs=(sim_101 sim_50)

for dir in ${dirs[*]}
do
    cd $dir
    ./cleanMe.sh
    cd ..
done

rm -f ./*.pdf
           
           
