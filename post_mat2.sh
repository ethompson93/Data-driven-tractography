#!/bin/bash

if [ "$2" == "" ];then
    echo ""
    echo " post matrix 2 <subject ID> <session ID>"
    echo " zips the fdt_matrix2.dot file "
    echo ""
    exit 1
fi

subject=$1
session=$2

results_dir=/share/neurodev/matrix2/${subject}/${session}

gzip --fast ${results_dir}/fdt_matrix2.dot


