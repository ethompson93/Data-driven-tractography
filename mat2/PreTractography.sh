#!/bin/bash

if [ "$4" == "" ];then
    echo ""
    echo "usage: $0 <DiffStudyFolder> <StrucStudyFolder> <Subject> <MSMflag>"
    echo "       MSMflag=0 uses the default surfaces, MSMflag=1 uses the MSM surfaces"
    echo ""
    exit 1
fi

module load fsl-img/6.0.2
module load connectome-uon/workbench-1.3.2

DiffStudyFolder=$1
StrucStudyFolder=$2
Subject=$3
MSMflag=$4

scriptsdir=/gpfs01/share/HCP/HCPyoung_adult/scripts/HCP-YA_NMF
WholeBrainTrajectoryLabels=${scriptsdir}/templates/config/WholeBrainFreeSurferTrajectoryLabelTableLut.txt
LeftCerebralTrajectoryLabels=${scriptsdir}/templates/config/LeftCerebralFreeSurferTrajectoryLabelTableLut.txt
RightCerebralTrajectoryLabels=${scriptsdir}/templates/config/RightCerebralFreeSurferTrajectoryLabelTableLut.txt
FreeSurferLabels=${scriptsdir}/templates/config/FreeSurferAllLut.txt


T1wDiffusionFolder="${DiffStudyFolder}/${Subject}/T1w/Diffusion"
DiffusionResolution=`${FSLDIR}/bin/fslval ${T1wDiffusionFolder}/data pixdim1`
DiffusionResolution=`printf "%0.2f" ${DiffusionResolution}`
LowResMesh=32
StandardResolution="2"


#Create lots of files in MNI space used in tractography

#NamingConventions
Caret7_Command="wb_command"
MNIFolder="MNINonLinear"
ROIsFolder="ROIs"
wmparc="wmparc"
ribbon="ribbon"
trajectory="Trajectory"

tempMSMsurf=""
if [ ${MSMflag} -eq 1 ] ; then
    echo "Using MSMAll surfaces..."
    tempMSMsurf="_MSMAll"
fi

#Make Paths
MNIFolder="${StrucStudyFolder}/${Subject}/${MNIFolder}"
ROIsFolder="${MNIFolder}/${ROIsFolder}"
ResultsFolder="${DiffStudyFolder}/${Subject}/MNINonLinear/Results/Tractography_NMF"
DownSampleFolder="${MNIFolder}/fsaverage_LR${LowResMesh}k"

if [ ! -e ${ResultsFolder} ] ; then
  mkdir -p ${ResultsFolder}
fi

if [ ! -e ${ROIsFolder} ] ; then
  mkdir ${ROIsFolder}
fi

if [ -e "$ROIsFolder"/temp ] ; then
  rm -r "$ROIsFolder"/temp
  mkdir "$ROIsFolder"/temp
else
  mkdir "$ROIsFolder"/temp
fi

#Uses pre-existing $ROIsFolder/wmparc.2.nii.gz
#Create riboon at standard 2mm resolution
${FSLDIR}/bin/flirt -interp nearestneighbour -in "${MNIFolder}"/"${ribbon}" -ref ${FSLDIR}/data/standard/MNI152_T1_2mm.nii.gz -applyisoxfm ${StandardResolution} -out "${ROIsFolder}"/ribbon."${StandardResolution}"
${Caret7_Command} -volume-label-import "$ROIsFolder"/ribbon."${StandardResolution}".nii.gz "$FreeSurferLabels" "$ROIsFolder"/ribbon."${StandardResolution}".nii.gz

${FSLDIR}/bin/fslmaths "$ROIsFolder"/ribbon."${StandardResolution}".nii.gz -sub "$ROIsFolder"/ribbon."${StandardResolution}".nii.gz "$ROIsFolder"/temp/trajectory
${FSLDIR}/bin/fslmaths "$ROIsFolder"/temp/trajectory -mul 1 "$ROIsFolder"/temp/delete_mask.nii.gz
${FSLDIR}/bin/fslmaths "$ROIsFolder"/temp/trajectory -mul 1 "$ROIsFolder"/temp/CC_mask.nii.gz

#LeftLateralVentricle, LeftInfLatVent, 3rdVentricle, 4thVentricle, CSF, LeftChoroidPlexus, RightLateralVentricle, RightInfLatVent, RightChoroidPlexus
wmparcStructuresToDeleteSTRING="4 5 14 15 24 31 43 44 63"
for Structure in $wmparcStructuresToDeleteSTRING ; do
  ${FSLDIR}/bin/fslmaths "$ROIsFolder"/"$wmparc"."$StandardResolution" -thr $Structure -uthr $Structure -bin "$ROIsFolder"/temp/$Structure
  ${FSLDIR}/bin/fslmaths "$ROIsFolder"/temp/$Structure -add "$ROIsFolder"/temp/delete_mask.nii.gz "$ROIsFolder"/temp/delete_mask.nii.gz
done
${FSLDIR}/bin/fslmaths "$ROIsFolder"/temp/delete_mask.nii.gz  -bin -sub 1 -mul -1 "$ROIsFolder"/temp/inverse_delete_mask.nii.gz

#CEREBELLAR_WHITE_MATTER_LEFT CEREBELLUM_LEFT THALAMUS_LEFT CAUDATE_LEFT PUTAMEN_LEFT PALLIDUM_LEFT BRAIN_STEM HIPPOCAMPUS_LEFT AMYGDALA_LEFT ACCUMBENS_LEFT DIENCEPHALON_VENTRAL_LEFT CEREBELLAR_WHITE_MATTER_RIGHT CEREBELLUM_RIGHT THALAMUS_RIGHT CAUDATE_RIGHT PUTAMEN_RIGHT PALLIDUM_RIGHT HIPPOCAMPUS_RIGHT AMYGDALA_RIGHT ACCUMBENS_RIGHT DIENCEPHALON_VENTRAL_RIGHT
wmparcStructuresToKeepSTRING="7 8 10 11 12 13 16 17 18 26 28 46 47 49 50 51 52 53 54 58 60"
for Structure in $wmparcStructuresToKeepSTRING ; do
  ${FSLDIR}/bin/fslmaths "$ROIsFolder"/"$wmparc"."$StandardResolution" -thr $Structure -uthr $Structure -bin "$ROIsFolder"/temp/$Structure
  ${FSLDIR}/bin/fslmaths "$ROIsFolder"/temp/$Structure -mul $Structure -add "$ROIsFolder"/temp/trajectory "$ROIsFolder"/temp/trajectory
done
${FSLDIR}/bin/fslmaths "$ROIsFolder"/temp/trajectory -bin -sub 1 -mul -1 "$ROIsFolder"/temp/inverse_trajectory_mask

#CORTEX_LEFT CEREBRAL_WHITE_MATTER_LEFT CORTEX_RIGHT CEREBRAL_WHITE_MATTER_RIGHT
RibbonStructures="2 3 41 42"
for Structure in $RibbonStructures ; do
  ${FSLDIR}/bin/fslmaths "${ROIsFolder}"/ribbon."${StandardResolution}" -thr $Structure -uthr $Structure -bin "$ROIsFolder"/temp/$Structure
  ${FSLDIR}/bin/fslmaths "$ROIsFolder"/temp/$Structure -mas "$ROIsFolder"/temp/inverse_trajectory_mask -mul $Structure -add "$ROIsFolder"/temp/trajectory "$ROIsFolder"/temp/trajectory
done

#Fornix, CC_Posterior, CC_Mid_Posterior, CC_Central, CC_MidAnterior, CC_Anterior
CorpusCallosumToAdd="250 251 252 253 254 255"
for Structure in $CorpusCallosumToAdd ; do
  ${FSLDIR}/bin/fslmaths "$ROIsFolder"/"$wmparc"."$StandardResolution" -thr $Structure -uthr $Structure -bin "$ROIsFolder"/temp/$Structure
  ${FSLDIR}/bin/fslmaths "$ROIsFolder"/temp/$Structure -add "$ROIsFolder"/temp/CC_mask.nii.gz "$ROIsFolder"/temp/CC_mask.nii.gz
done

${FSLDIR}/bin/fslmaths "$ROIsFolder"/temp/trajectory -bin -sub 1 -mul -1 "$ROIsFolder"/temp/inverse_trajectory_mask.nii.gz
${FSLDIR}/bin/fslmaths "$ROIsFolder"/temp/CC_mask.nii.gz -mas "$ROIsFolder"/temp/inverse_trajectory_mask.nii.gz "$ROIsFolder"/temp/CC_to_add
${FSLDIR}/bin/fslmaths "$ROIsFolder"/temp/CC_to_add -mul 2 -add "$ROIsFolder"/temp/trajectory "$ROIsFolder"/temp/trajectory
${FSLDIR}/bin/fslmaths "$ROIsFolder"/temp/trajectory -mas "$ROIsFolder"/temp/inverse_delete_mask.nii.gz "$ROIsFolder"/temp/trajectory

${FSLDIR}/bin/fslmaths "$ROIsFolder"/temp/trajectory -bin "$ROIsFolder"/Whole_Brain_"$trajectory"_ROI_"$StandardResolution"

${Caret7_Command} -volume-label-import "$ROIsFolder"/temp/trajectory.nii.gz $WholeBrainTrajectoryLabels "$MNIFolder"/Whole_Brain_"$trajectory"_"$StandardResolution".nii.gz -discard-others -unlabeled-value 0
${Caret7_Command} -volume-label-import "$ROIsFolder"/temp/trajectory.nii.gz $LeftCerebralTrajectoryLabels "$MNIFolder"/L_Cerebral_"$trajectory"_"$StandardResolution".nii.gz -discard-others -unlabeled-value 0
${Caret7_Command} -volume-label-import "$ROIsFolder"/temp/trajectory.nii.gz $RightCerebralTrajectoryLabels "$MNIFolder"/R_Cerebral_"$trajectory"_"$StandardResolution".nii.gz -discard-others -unlabeled-value 0

${FSLDIR}/bin/fslmaths "$ROIsFolder"/temp/trajectory.nii.gz -sub "$ROIsFolder"/temp/trajectory.nii.gz -add "$MNIFolder"/L_Cerebral_"$trajectory"_"$StandardResolution".nii.gz -bin "$ROIsFolder"/L_Cerebral_"$trajectory"_ROI_"$StandardResolution"
${FSLDIR}/bin/fslmaths "$ROIsFolder"/temp/trajectory.nii.gz -sub "$ROIsFolder"/temp/trajectory.nii.gz -add "$MNIFolder"/R_Cerebral_"$trajectory"_"$StandardResolution".nii.gz -bin "$ROIsFolder"/R_Cerebral_"$trajectory"_ROI_"$StandardResolution"

rm -r "$ROIsFolder"/temp

# Extract atlas-derived ROIs that could be used as subcortical volume seeds.
ROIStructuresToSeed="26 58 18 54 16 11 50 8 47 28 60 17 53 13 52 12 51 10 49"
ROINames=("ACCUMBENS_LEFT" "ACCUMBENS_RIGHT" "AMYGDALA_LEFT" "AMYGDALA_RIGHT" "BRAIN_STEM" "CAUDATE_LEFT" "CAUDATE_RIGHT" "CEREBELLUM_LEFT" "CEREBELLUM_RIGHT" "DIENCEPHALON_VENTRAL_LEFT" "DIENCEPHALON_VENTRAL_RIGHT" "HIPPOCAMPUS_LEFT" "HIPPOCAMPUS_RIGHT" "PALLIDUM_LEFT" "PALLIDUM_RIGHT" "PUTAMEN_LEFT" "PUTAMEN_RIGHT" "THALAMUS_LEFT" "THALAMUS_RIGHT")
count=0
for Structure in $ROIStructuresToSeed ; do
    ${FSLDIR}/bin/fslmaths "$ROIsFolder"/Atlas_ROIs."$StandardResolution" -thr $Structure -uthr $Structure -bin "$ResultsFolder"/CIFTI_STRUCTURE_${ROINames[$count]}
    count=$(( $count + 1 ))
done

# Create Probtrackx-Compatible Pial and White-matter Surfaces
${FSLDIR}/bin/surf2surf -i ${DownSampleFolder}/${Subject}.L.white${tempMSMsurf}.${LowResMesh}k_fs_LR.surf.gii -o ${ResultsFolder}/white.L.asc --outputtype=ASCII --values=${DownSampleFolder}/${Subject}.L.atlasroi.${LowResMesh}k_fs_LR.shape.gii
${FSLDIR}/bin/surf2surf -i ${DownSampleFolder}/${Subject}.R.white${tempMSMsurf}.${LowResMesh}k_fs_LR.surf.gii -o ${ResultsFolder}/white.R.asc --outputtype=ASCII --values=${DownSampleFolder}/${Subject}.R.atlasroi.${LowResMesh}k_fs_LR.shape.gii
${FSLDIR}/bin/surf2surf -i ${DownSampleFolder}/${Subject}.L.pial${tempMSMsurf}.${LowResMesh}k_fs_LR.surf.gii -o ${ResultsFolder}/pial.L.asc --outputtype=ASCII --values=${DownSampleFolder}/${Subject}.L.atlasroi.${LowResMesh}k_fs_LR.shape.gii
${FSLDIR}/bin/surf2surf -i ${DownSampleFolder}/${Subject}.R.pial${tempMSMsurf}.${LowResMesh}k_fs_LR.surf.gii -o ${ResultsFolder}/pial.R.asc --outputtype=ASCII --values=${DownSampleFolder}/${Subject}.R.atlasroi.${LowResMesh}k_fs_LR.shape.gii
