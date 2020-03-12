#!/bin/bash

Usage() {
    cat << EOF

Usage: run_jobs.sh <sub_list> <res> <partition>

       <sub_list>   List of subject IDs
       <res>        The resolution to sample the target mask to in mm, e.g. 2.5
       <partition>  The cluster partition to use for fsl_sub = "hpc" or "img"

EOF
    exit 1
}

[ "$1" = "" ] && Usage

if [ $# -lt 2 ]; then
    echo "Incorrect arguments, please check the usage and retry."
    echo $Usage
    exit 1
fi

input=$1
res=$2 # the resolution of the target mask
partition=$3

#input=${scriptsdir}/mat2/sublist
#res=2.5
#partition=hpc

if [ ${partition} == "hpc" ]; then
  q_flag="-a"
elif [ ${partition} == "img" ]; then
  q_flag=""
else
  echo 'Must select either "hpc" or "img" as the partition'
  exit 1
fi

module load fsl-img/6.0.2
module load connectome-uon/workbench-1.3.2

scriptsdir=/gpfs01/share/HCP/HCPyoung_adult/scripts/HCP-YA_NMF
StudyFolder=/gpfs01/share/HCP/HCPyoung_adult
DiffStudyFolder=${StudyFolder}/Diffusion
StructStudyFolder=${StudyFolder}/Structural
RFExt=MNINonLinear/Results/Tractography_NMF

MSMflag=0 # 0 = do nmot use MSMall surfaces
SeedsMode=0 # 0 = seed from L/R WGB and from subcortical
DistanceThreshold=-1 # -1 = no distance threshold

# Resample MNI mask
if [ ! -f "${scriptsdir}/templates/mni_brain_mask_${res}.nii.gz" ] || \
[ ! -f "${scriptsdir]}/templates/91282_Greyordinates/Atlas_ROIs_noCereb_noBS.2.nii.gz" ]; then
  echo "Resampling MNI brain mask..."
  bash ${scriptsdir}/mat2/resample_mni.sh ${res}
fi

curDir=`pwd`
subDir=${scriptsdir}/jobs
if [ -d ${subDir} ]; then
    i=0
    while [ i=0 ]; do
        if [ -d ${subDir} ]; then
	    subDir="${subDir}+"
	else
	    i=1; break
	fi
    done
    echo "${subDir}"
fi
mkdir ${subDir}; cd ${subDir}

# Loop through subjets and submit jobs
echo "Submitting jobs..."
ii=0
for subID in `cat $input`
do
    echo ${subID}
    if [ ! -e ${DiffStudyFolder}/${subID}/${RFExt} ]; then
      mkdir ${DiffStudyFolder}/${subID}/${RFExt}
    else
      rm ${DiffStudyFolder}/${subID}/${RFExt} -r
      mkdir ${DiffStudyFolder}/${subID}/${RFExt}
    fi

    # Submit Pre-tractography job
    temp=`jobsub -j -q cpu -p 1 -t 00:10:00 -m 1 -s ${subID}_PrMat2 -c "bash \
      ${scriptsdir}/Data-driven-tractography/mat2/PreTractography.sh ${DiffStudyFolder} ${StructStudyFolder} ${subID} ${MSMflag}"`
    jobID=`echo -e $temp | awk '{print $NF}'`

    # Submit Tractography job
    jobsub -j -q cpu -p 1 -t 00:10:00 -m 1 -w ${jobID} -s ${subID}_RunMat2 -c "bash \
      ${scriptsdir}/Data-driven-tractography/mat2/RunMatrix2.sh ${DiffStudyFolder} ${StructStudyFolder} ${subID} ${DistanceThreshold}\
      ${res} ${SeedsMode} ${q_flag}"

    ii=$((ii + 1)); if [ $ii -ge 7 ]; then ii=0; fi
done

cd $curDir
