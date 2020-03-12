#!/bin/bash

if [ "$1" == "" ];then
    echo ""
    echo " post matrix 2 <subject ID>"
    echo " zips the fdt_matrix2.dot file "
    echo ""
    exit 1
fi

subject=$1

results_dir=/gpfs01/share/HCP/HCPyoung_adult/Diffusion/${subject}/MNINonLinear/Results/Tractography_NMF

gzip --fast ${results_dir}/fdt_matrix2.dot


