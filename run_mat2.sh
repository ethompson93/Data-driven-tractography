#!/bin/bash

if [ "$2" == "" ];then
    echo ""
    echo " connectivity matrix <subject ID> <session ID>"
    echo " uses probtrackx to generate matrix2 for ICA "
    echo ""
    exit 1
fi

subject=$1
session=$2
shift;shift;

results_dir=/share/neurodev/matrix2/${subject}/${session}
anat_dir=/share/neurodev/Surfaces32k_june2018/reconstructions_june2018/sub-${subject}/${session}/anat/fsaverage_LR32k
warp_dir=/share/neurodev/dHCP_neo_dMRI_v2/${subject}/${session}/Diffusion/xfms
diffusion_dir=/share/neurodev/dHCP_neo_dMRI_v2/${subject}/${session}/Diffusion.bedpostX
vol_template_dir=/share/neurodev/atlas/atlas-serag/T2

subcortical_seeds=/share/neurodev/matrix2/subcortical_seeds_2mm.nii.gz 
target_mask=/share/neurodev/matrix2/template-40-mask_2mm_novent.nii.gz

#run ptx on subject data from template seeds

echo "running ptx for $subj"
probtrackx2_gpu -s ${diffusion_dir}/merged --mask=${diffusion_dir}/nodif_brain_mask.nii.gz --xfm=${warp_dir}/std40w2diff_warp.nii.gz --invxfm=${warp_dir}/diff2std40w_warp.nii.gz --seedref=/share/neurodev/matrix2/template-40-mask_2mm.nii.gz -x ${results_dir}/seeds.txt --stop=${results_dir}/stop.txt --wtstop=${results_dir}/wtstop.txt --omatrix2 --target2=${target_mask} --loopcheck --forcedir -c 0.2 --sampvox=2 --randfib=1 --forcefirststep --dir=${results_dir} --nsamples=10000 --pd


