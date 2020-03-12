#!/bin/bash

Usage() {
    cat << EOF

Usage: resample_mni.sh <res>

       <res>   The resolution of the brain mask

EOF
    exit 1
}

[ "$1" = "" ] && Usage

if [ $# -lt 1 ]; then
    echo "Incorrect arguments, please check the usage and retry."
    echo $Usage
    exit 1
fi

module load fsl-img/6.0.2
module load connectome-uon/workbench-1.3.2

res=$1

# Prepare MNI brian mask
scriptsdir=/gpfs01/share/HCP/HCPyoung_adult/scripts/HCP-YA_NMF
in=${scriptsdir}/templates/MNI152_T1_2mm_brain_mask.nii.gz
out=${scriptsdir}/templates/mni_brain_mask_${res}
${FSLDIR}/bin/flirt -in ${in} -ref ${in} -applyisoxfm ${res} -interp nearestneighbour -out ${out}

echo "Resampled to ${res} mm: ${out}"

# Prepare the volume template
dir=${scriptsdir}/templates/91282_Greyordinates
lut=${scriptsdir}/templates/config/SubCorticalTrajectory_noCereb_noBS_LabelTableLut.txt
remove=(8 47 16) # CEREBELLUM_LEFT CEREBELLUM_RIGHT BRAIN_STEM
delCMD="${FSLDIR}/bin/fslmaths ${dir}/Atlas_ROIs.2"

for i in ${remove[@]}; do
  ${FSLDIR}/bin/fslmaths ${dir}/Atlas_ROIs.2 -thr ${i} -uthr ${i} ${dir}/${i}
  delCMD="${delCMD} -sub ${dir}/${i}"
done
delCMD="${delCMD} ${dir}/Atlas_ROIs_noCereb_noBS.2"
$delCMD

for i in ${remove[@]}; do rm ${dir}/${i}.nii.gz; done

wb_command -volume-label-import ${dir}/Atlas_ROIs_noCereb_noBS.2.nii.gz ${lut} ${dir}/Atlas_ROIs_noCereb_noBS.2.nii.gz

echo "Removed `echo ${#remove[@]}` structures from the volume label file"
echo ">>>> ${dir}/Atlas_ROIs_noCereb_noBS.2.nii.gz"
