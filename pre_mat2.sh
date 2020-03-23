#!/bin/bash

if [ "$2" == "" ];then
    echo ""
    echo " pre matrix 2 <subject ID> <session ID>"
    echo " generates a warp from structural space to 40 week template "
    echo " transforms surface files to standard space to be used as seeds in ptx "
    echo ""
    exit 1
fi

subject=$1
session=$2
shift;shift;
#module load fsl-uon/binary/5.0.11
module load connectome-uon/workbench-1.3.2
#module load cuda/local/9.2

results_dir=/share/neurodev/matrix2/${subject}/${session}
anat_dir=/share/neurodev/Surfaces32k_june2018/reconstructions_june2018/sub-${subject}/${session}/anat/fsaverage_LR32k
warp_dir=/share/neurodev/dHCP_neo_dMRI_v2/${subject}/${session}/Diffusion/xfms
diffusion_dir=/share/neurodev/dHCP_neo_dMRI_v2/${subject}/${session}/Diffusion.bedpostX
vol_template_dir=/share/neurodev/atlas/atlas-serag/T2

METRIC_L=/share/neurodev/Surfaces32k_june2018/new_surface_template/roi_matteo/week40.L.atlasroi.32k.inv.func.gii 
METRIC_R=/share/neurodev/Surfaces32k_june2018/new_surface_template/roi_matteo/week40.R.atlasroi.32k.inv.func.gii
mkdir /share/neurodev/matrix2/${subject}
mkdir ${results_dir}

age=`cat /share/neurodev/dHCP_neo_dMRI_v2/${subject}/${session}/age`
if [ "${age}" -eq "45" ] ; then age=44; fi #use 44 week template for subjects aged 45 weeks

if [ ! -f ${results_dir}/sub-${subject}_${session}_std40w_left_white.32k_fs_LR.surf.gii ] || [ ! -f ${results_dir}/sub-${subject}_${session}_std40w_right_white.32k_fs_LR.surf.gii ]; then
	if [ "${age}" -ne "40" ] ; then
		#generate str2std40 warp
		convertwarp -r ${vol_template_dir}/template-40 --warp1=${warp_dir}/str2std_warp.nii.gz --warp2=/share/neurodev/atlas/atlas-serag/allwarps/template-${age}_to_template-40_warp.nii.gz -o ${results_dir}/str2std40w_warp.nii.gz
		invwarp -w ${results_dir}/str2std40w_warp.nii.gz -o ${results_dir}/std40w2str_warp.nii.gz -r /share/neurodev/dHCP_neo_dMRI_v2/${subject}/${session}/T2w/T2w.nii.gz

		#register msm-ed surfaces to template space
		echo "applying warpfield"
		for surf in pial white; do
			for hemi in left right; do
				wb_command -surface-apply-warpfield ${anat_dir}/sub-${subject}_${session}_${hemi}_${surf}.32k_fs_LR.surf.gii ${results_dir}/std40w2str_warp.nii.gz ${results_dir}/sub-${subject}_${session}_std40w_${hemi}_${surf}.32k_fs_LR.surf.gii -fnirt ${results_dir}/str2std40w_warp.nii.gz
			done

		done
	else

	echo "applying warpfield"
		for surf in pial white; do
			for hemi in left right; do
			wb_command -surface-apply-warpfield ${anat_dir}/sub-${subject}_${session}_${hemi}_${surf}.32k_fs_LR.surf.gii ${warp_dir}/std2str_warp.nii.gz ${results_dir}/sub-${subject}_${session}_std40w_${hemi}_${surf}.32k_fs_LR.surf.gii -fnirt ${warp_dir}/str2std_warp.nii.gz
			done

		done
	fi
fi

for surf in pial white; do
	surf2surf -i ${results_dir}/sub-${subject}_${session}_std40w_left_${surf}.32k_fs_LR.surf.gii -o $results_dir/L.${surf}.asc --outputtype=ASCII --values=$METRIC_L
	surf2surf -i ${results_dir}/sub-${subject}_${session}_std40w_right_${surf}.32k_fs_LR.surf.gii -o $results_dir/R.${surf}.asc --outputtype=ASCII --values=$METRIC_R
done

subcortical_seeds=/share/neurodev/matrix2/subcortical_seeds_2mm.nii.gz 

echo $results_dir/"L.white.asc" > $results_dir/seeds.txt 
echo $results_dir/"R.white.asc" >>$results_dir/seeds.txt
echo ${subcortical_seeds} >>$results_dir/seeds.txt

echo $results_dir/"L.white.asc" > $results_dir/wtstop.txt 
echo $results_dir/"R.white.asc" >>$results_dir/wtstop.txt

echo $results_dir/"L.pial.asc" > $results_dir/stop.txt 
echo $results_dir/"R.pial.asc" >>$results_dir/stop.txt
