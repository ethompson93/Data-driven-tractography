#!/bin/bash

module load fsl-uon/binary/5.0.11
module load connectome-uon/workbench-1.3.2
module load python-img/gcc6.3.0/2.7.15


subject_list="/gpfs01/share/HCP/HCPyoung_adult/scripts/HCP-YA_NMF/Data-driven-tractography/mat2/sublist"
#subject_list="/gpfs01/share/HCP/HCPyoung_adult/scripts/HCP-YA_NMF/Data-driven-tractography/NMF/split/1"
res=2.5
results_dir="/gpfs01/share/HCP/HCPyoung_adult/Diffusion/NMF"
if [ ! -d ${results_dir} ]; then mkdir ${results_dir}; fi
scripts_dir="/gpfs01/share/HCP/HCPyoung_adult/scripts/HCP-YA_NMF/Data-driven-tractography/NMF"
data_dir="/gpfs01/share/HCP/HCPyoung_adult/Diffusion"

templatedir="/gpfs01/share/HCP/HCPyoung_adult/scripts/HCP-YA_NMF/templates/"
volume_template="${templatedir}/mni_brain_mask_${res}.nii.gz"
roi_path_l="${templatedir}/91282_Greyordinates/L.atlasroi.32k_fs_LR.shape.gii"
roi_path_r="${templatedir}/91282_Greyordinates/R.atlasroi.32k_fs_LR.shape.gii"
#label_volume="${templatedir}/91282_Greyordinates/Atlas_ROIs.${res}.nii.gz"
label_volume="${templatedir}/91282_Greyordinates/Atlas_ROIs_noCereb_noBS.2.nii.gz"

curDir=`pwd`
subDir=${scripts_dir}/jobs
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

jobIDlist=""; q_list=(imgcomputeq); ii=0
for subjID in `cat $subject_list`
do
    echo "processing ${subjID}"
    if [ ! -f "${data_dir}/${subjID}/MNINonLinear/Results/Tractography_NMF/fdt_matrix2.npz" ]; then
      	# convert matrix 2 to python sparse format
      	if [ ! -f "${data_dir}/${subjID}/MNINonLinear/Results/Tractography_NMF/fdt_matrix2.dot.gz" ]; then
      	    temp=`jobsub -j -q ${q_list[$ii]} -p 1 -t 6:00:00 -m 15 -s ${subjID}_zip -c "bash ${scripts_dir}/post_mat2.sh ${subjID}"`
            jobID=`echo -e $temp | awk '{print $NF}'`
      	    temp=`jobsub -j -q ${q_list[$ii]} -p 1 -t 6:00:00 -m 60 -w ${jobID} -s ${subjID}_NMFconv -c "python ${scripts_dir}/dot2npz.py ${data_dir}/${subjID}/MNINonLinear/Results/Tractography_NMF"`
            temp=`echo -e $temp | awk '{print $NF}'`
            jobIDlist="${jobIDlist}${temp}:"
      	else
      	    temp=`jobsub -j -q ${q_list[$ii]} -p 1 -t 6:00:00 -m 60 -s ${subjID}_NMFconv -c "python ${scripts_dir}/dot2npz.py ${data_dir}/${subjID}/MNINonLinear/Results/Tractography_NMF"`
            temp=`echo -e $temp | awk '{print $NF}'`
            jobIDlist="${jobIDlist}${temp}:"
      	fi
        ii=$((ii + 1)); if [ $ii -ge ${#q_list[@]} ]; then ii=0; fi
      else
        echo "Already processed..."
    fi
done
jobIDlist=`echo ${jobIDlist:0:-1}`
# average matrices in batches of 10
# if [ -d ${results_dir}/temp ]; then
#   rm -rf ${results_dir}/temp; mkdir ${results_dir}/temp
# else
#   mkdir ${results_dir}/temp
# fi

# imgcomputeq jobs
i=1
temp=`jobsub -j -q imgcomputeq -p 1 -t 1-00:00:00 -m 170 -w ${jobIDlist} -s aveM_b${i} -c "python ${scripts_dir}/average_matrices.py ${scripts_dir}/split/${i} ${data_dir} ${results_dir}/temp/average_mat2_${i}"`
jobID=`echo -e $temp | awk '{print $NF}'`
for i in {2..5}; do
  temp=`jobsub -j -q imgcomputeq -p 1 -t 1-00:00:00 -m 170 -w ${jobID} -s aveM_b${i} -c "python ${scripts_dir}/average_matrices.py ${scripts_dir}/split/${i} ${data_dir} ${results_dir}/temp/average_mat2_${i}"`
  jobID=`echo -e $temp | awk '{print $NF}'`
done

# imghmemq jobs
i=6
temp=`jobsub -j -q imghmemq -p 1 -t 1-00:00:00 -m 170 -w ${jobIDlist} -s aveM_b${i} -c "python ${scripts_dir}/average_matrices.py ${scripts_dir}/split/${i} ${data_dir} ${results_dir}/temp/average_mat2_${i}"`
jobID=`echo -e $temp | awk '{print $NF}'`
for i in {7..10}; do
  temp=`jobsub -j -q imghmemq -p 1 -t 1-00:00:00 -m 170 -w ${jobID} -s aveM_b${i} -c "python ${scripts_dir}/average_matrices.py ${scripts_dir}/split/${i} ${data_dir} ${results_dir}/temp/average_mat2_${i}"`
  jobID=`echo -e $temp | awk '{print $NF}'`
done


# final average call
temp=`jobsub -j -q imgcomputeq -p 1 -t 1-00:00:00 -m 170 -s aveM_fin -w ${jobID} -c "python ${scripts_dir}/average_matrices_batch.py ${results_dir}/temp ${results_dir}/average_mat2"`
jobID=`echo -e $temp | awk '{print $NF}'`


# run NMF
n_components=200
alpha=0.05
NMFfilename="${results_dir}/${n_components}_NMF"
jobsub -j -q imgcomputeq -p 1 -t 1-00:00:00 -m 170 -w ${jobID} -s runNMF_HCP_${n_components} -c "python ${scripts_dir}/run_NMF.py ${results_dir}/average_mat2.npz ${NMFfilename} ${n_components} ${alpha}"

#run PCA
n_PCs=400
PCAfilename="${results_dir}/${n_PCs}_PCs"
temp=`jobsub -j -q imgcomputeq -p 1 -t 1-00:00:00 -m 170 -s runPCA_HCP_${n_components} -c "python ${scripts_dir}/run_PCA.py ${results_dir}/average_mat2.npz ${PCAfilename} ${n_PCs}"`
jobID=`echo -e $temp | awk '{print $NF}'`

#run ICA
n_components=200
ICAfilename="${results_dir}/${n_components}_ICA"
jobsub -j -q imgcomputeq -p 1 -t 1-00:00:00 -m 170 -w ${jobID} -s runICA_HCP_${n_components} -c "python ${scripts_dir}/run_ICA.py ${PCAfilename}.npy ${results_dir}/average_mat2.npz ${ICAfilename} ${n_components}"



# convert white matter components to nifti format
for decomposition in ICA NMF; do
	jobsub -j -q imgcomputeq -p 1 -t 00:10:00 -m 5 -s wmconv_NMF -c "python ${scripts_dir}/npy2nifti.py ${results_dir}/${n_components}_${decomposition}_wm.npy ${data_dir}/100206/MNINonLinear/Results/Tractography_NMF ${volume_template}"
# convert grey matter components to cifti
	jobsub -j -q imgcomputeq -p 1 -t 00:10:00 -m 5 -s gmconv_NMF -c "python ${scripts_dir}/npy2cifti.py ${results_dir}/${n_components}_${decomposition}_gm.npy ${data_dir}/100206/MNINonLinear/Results/Tractography_NMF ${roi_path_l} ${roi_path_r} ${label_volume}"
done

# Launch dual regression
bash ${scripts_dir}/NNLS/NNLS_parallelisation.sh ${n_components}
