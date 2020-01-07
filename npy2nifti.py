import numpy as np
import nibabel as nib

#path to white matter component matrix in .npy format that you want to convert to nifti
component_path="/share/neurodev/matrix2/Results/NMF_paper/NMF/5_NMFcomps_split1.npy"

#tractspace coordinates from Fdt
coordinate_path="/share/neurodev/matrix2/CC00069XX12/ses-26300/tract_space_coords_for_fdt_matrix2"

#reference image used as target for tractography
ref_path="/share/neurodev/matrix2/template-40-mask_2mm_novent.nii.gz"


ref_img =nib.load(ref_path)
components=np.load(component_path)

#load in tract space coordinates
file = open(coordinate_path, "r")
coords = np.loadtxt(file)
file.close()
coords = coords.astype(int)

(xdim, ydim, zdim)=ref_img.shape
ref_affine =ref_img.affine
n_comp, n_target = components.shape

comps_mat = np.zeros((xdim, ydim, zdim, n_comp))
for j in range(0, n_comp):                  
	for i in range(0, int(n_target)):
		comps_mat[coords[i,0], coords[i,1], coords[i,2], j]=components[j,i]

img = nib.Nifti1Image(comps_mat, ref_affine)

nib.save(img, component_path[:-4] + ".nii.gz")
