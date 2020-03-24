import numpy as np
import nibabel as nib
import sys

#path to white matter component matrix in .npy format that you want to convert to nifti
component_path = sys.argv[1]

#path to a directory containing the probtrack2 output (coords should be the same for all subjects)
fdt_dir = sys.argv[2]
coordinate_path = fdt_dir + "/tract_space_coords_for_fdt_matrix2"

#reference image used as target for tractography
ref_path = sys.argv[3]


ref_img = nib.load(ref_path)
components = np.load(component_path)

if components.ndim == 1:
	components = components[np.newaxis, :]

#load in tract space coordinates
file = open(coordinate_path, "r")
coords = np.loadtxt(file)
file.close()
coords = coords.astype(int)

(xdim, ydim, zdim)=ref_img.shape
ref_affine =ref_img.affine
n_comp, n_target = components.shape

#convert data to nifti coordinates
comps_mat = np.zeros((xdim, ydim, zdim, n_comp))
for j in range(0, n_comp):                  
	for i in range(0, int(n_target)):
		comps_mat[coords[i,0], coords[i,1], coords[i,2], j]=components[j,i]

img = nib.Nifti1Image(comps_mat, ref_affine)

nib.save(img, component_path[:-4] + ".nii.gz")
