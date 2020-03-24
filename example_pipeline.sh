#!/bin/bash

module load fsl-uon/binary/5.0.11
module load connectome-uon/workbench-1.3.2
module load python-img/gcc6.3.0/2.7.15


subject_list="/gpfs01/home/ppxet1/scripts/NMF_paper/pipeline/subject_list.csv"
results_dir="/gpfs01/home/ppxet1/tests/pipeline_output"
scripts_dir="/gpfs01/home/ppxet1/scripts/NMF_paper/pipeline"
data_dir="/share/neurodev/matrix2"

n_PCs=400
n_components=10

volume_template="/share/neurodev/matrix2/template-40-mask_2mm_novent.nii.gz"
roi_path_l="/share/neurodev/matrix2/week40.L.atlasroi.32k.inv.func.gii"
roi_path_r="/share/neurodev/matrix2/week40.R.atlasroi.32k.inv.func.gii"
label_volume="/share/neurodev/matrix2/label_vol.nii.gz"

PCAfilename="${results_dir}/${n_PCs}_PCs"
ICAfilename="${results_dir}/${n_components}_ICA"
NMFfilename="${results_dir}/${n_components}_NMF"


{
read
		
while IFS=, read -r N subjID sesID remainder ; do
	echo "processing ${subjID} ses-${sesID}"
	#prepare data
	${scripts_dir}/pre_mat2.sh ${subjID} ses-${sesID}

	#generate matrix 2
	${scripts_dir}/run_mat2.sh ${subjID} ses-${sesID}

	#convert matrix 2 to python sparse format
	${scripts_dir}/post_mat2.sh ${subjID} ses-${sesID}
	python ${scripts_dir}/dot2npz.py ${data_dir}/${subjID}/ses-${sesID}/fdt_matrix2.dot.gz
	
done 

} < ${subject_list}

#average matrices together
python ${scripts_dir}/average_matrices.py ${subject_list} ${data_dir} ${results_dir}/average_mat2

#run PCA
python ${scripts_dir}/run_PCA.py ${results_dir}/average_mat2.npz ${PCAfilename} ${n_PCs}

#run ICA
python ${scripts_dir}/run_ICA.py ${PCAfilename}.npy ${results_dir}/average_mat2.npz ${ICAfilename} ${n_components}

#run NMF
python ${scripts_dir}/run_NMF.py ${results_dir}/average_mat2.npz ${NMFfilename} ${n_components}

#convert white matter components to nifti format
for decomposition in ICs NMF; do
	python ${scripts_dir}/npy2nifti.py ${results_dir}/${n_components}_${decomposition}_wm.npy ${data_dir}/CC00069XX12/ses-26300 ${volume_template}

#convert grey matter components to cifti

	python ${scripts_dir}/npy2cifti.py ${results_dir}/${n_components}_${decomposition}_gm.npy ${data_dir}/CC00069XX12/ses-26300 ${roi_path_l} ${roi_path_r} ${label_volume}
done


#generate parcellations for group level results
for decomposition in ICs NMF; do
	python ${scripts_dir}/parcellate.py ${results_dir}/${n_components}_${decomposition}_gm.npy ${results_dir}/${n_components}_${decomposition}_parc.npy 

done

#run non-negative dual regression
{
read
		
while IFS=, read -r N subjID sesID remainder ; do
	echo "running dual regression for ${subjID} ses-${sesID}"
	python NNLS_dual_regression.py ${results_dir}/${n_components}_NMF_gm.npy ${data_dir}/${subjID}/ses-${sesID}/fdt_matrix2.npz ${results_dir}/${subID}_ses-${sesID}_${n_components}_DR 4
	
done 

} < ${subject_list}





