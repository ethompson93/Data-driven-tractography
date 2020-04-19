import numpy as np
import nibabel as nib
from nibabel import cifti2
import os.path
import sys

#path to grey matter component matrix in .npy format that you want to convert to cifti
component_path = sys.argv[1]

#seed space coordinates from Fdt
fdt_dir = sys.argv[2]
coordinate_path = fdt_dir + "/coords_for_fdt_matrix2"

#paths to cortical ROIs used to seed tractography
roi_path_l = sys.argv[3]
roi_path_r= sys.argv[4]

#path to subcortical seed volume
subcortical_path = sys.argv[5]

#########################################################################################
#load components
components = np.load(component_path)
if components.ndim == 1:
	components = components[:, np.newaxis]

n_comp = np.shape(components)[1]

#load in seed space coordinates
file = open(coordinate_path, "r")
coords = np.loadtxt(file).astype(int)
file.close()
volume_coords = coords[coords[:,3] >= 2]

#load subcortical seed volume
subcortical_vol = nib.load(subcortical_path)
subcortical_roi = subcortical_vol.get_data()

#load gifti ROIs
roi_left = nib.load(roi_path_l).darrays[0].data != 0
roi_right = nib.load(roi_path_r).darrays[0].data != 0

#set up cifti brain model axes
bm_ctx_left = cifti2.BrainModelAxis.from_mask(roi_left, name="CortexLeft")
bm_ctx_right = cifti2.BrainModelAxis.from_mask(roi_right, name="CortexRight")

bm_subcortical = cifti2.BrainModelAxis.from_mask(subcortical_roi, affine=subcortical_vol.affine, name="other")

bm_subcortical.voxel = volume_coords[:,:3]

bm = bm_ctx_left + bm_ctx_right + bm_subcortical
sc = cifti2.ScalarAxis(np.arange(n_comp).astype("str"))

#save cifti
hdr = cifti2.Cifti2Header.from_axes((sc, bm))
img = cifti2.Cifti2Image(components.T, hdr)
new_fname = os.path.splitext(component_path)[0] + ".dscalar.nii"

nib.save(img, new_fname)
