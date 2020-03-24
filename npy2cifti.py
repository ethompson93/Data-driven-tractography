import numpy as np
import nibabel as nib
import copy
import subprocess
import sys

#path to grey matter component matrix in .npy format that you want to convert to cifti
component_path = sys.argv[1]
fname = component_path[:-4]

#seed space coordinates from Fdt
fdt_dir = sys.argv[2]
coordinate_path = fdt_dir + "/coords_for_fdt_matrix2"

#paths to cortical ROIs used to seed tractography
roi_path_l = sys.argv[3]
roi_path_r= sys.argv[4]

#path to label volume
label_vol_path = sys.argv[5]


#########################################################################################
#load components
components = np.load(component_path)
if components.ndim == 1:
	components = components[:, np.newaxis]

n_comp = np.shape(components)[1]

#load in seed space coordinates
file = open(coordinate_path, "r")
coords = np.loadtxt(file)
file.close()
coords = coords.astype(int)

#seperate out left and right hemispheres
left = coords[coords[:,3] == 0]
right = coords[coords[:,3] == 1]
volume = coords[coords[:,3] >= 2]

n_l = np.shape(left)[0]
n_r = np.shape(right)[0]
n_v = np.shape(volume)[0]

comps_l= components[:n_l,:]
comps_r = components[n_l:(n_r+n_l),:]
comps_v = components[-n_v:,:]

#load in gifti metric files
left_roi = nib.load(roi_path_l)
right_roi = nib.load(roi_path_r)

left_roi_ind = np.where(left_roi.darrays[0].data > 0)
right_roi_ind = np.where(right_roi.darrays[0].data > 0)

tmp_l = nib.load(roi_path_l)
tmp_r = nib.load(roi_path_r)
tmp_l.darrays[0].data.setflags(write=1)
tmp_r.darrays[0].data.setflags(write=1)

tmp_l.darrays[0].data[left_roi_ind] = comps_l[:,0]
tmp_r.darrays[0].data[right_roi_ind] = comps_r[:,0]
    
#save a gifti metric file for each component
for j in range(1, n_comp) :
	left = copy.deepcopy(left_roi.darrays[0].data)
        right = copy.deepcopy(right_roi.darrays[0].data)
        left[left_roi_ind] = comps_l[:,j].astype("float32")
        right[right_roi_ind] = comps_r[:,j].astype("float32")
        tmp_l.add_gifti_data_array(nib.gifti.gifti.GiftiDataArray(left))
        tmp_r.add_gifti_data_array(nib.gifti.gifti.GiftiDataArray(right))

nib.save(tmp_r, fname + ".R.shape.gii")
nib.save(tmp_l, fname + ".L.shape.gii")
    
#save volume part as nifti
ref_img = nib.load(label_vol_path)
ref_affine =ref_img.affine
(x, y, z) = ref_img.shape
volume_components = np.zeros((x, y, z, n_comp))
for n in range(n_comp):
	for v in range(n_v):
		volume_components[volume[v,0], volume[v,1], volume[v,2], n]=comps_v[v,n]

img = nib.Nifti1Image(volume_components, ref_affine)
nib.save(img, fname + ".nii.gz")

    
#combine into a cifti
subprocess.call(["wb_command", "-cifti-create-dense-scalar", "{}.dscalar.nii".format(fname),
                     "-volume", "{}.nii.gz".format(fname), label_vol_path, "-left-metric", "{}.L.shape.gii".format(fname),
                     "-roi-left", roi_path_l, "-right-metric", "{}.R.shape.gii".format(fname), "-roi-right", roi_path_r])

#remove unnecessary files
subprocess.call(["rm", "{}.nii.gz".format(fname)])
subprocess.call(["rm", "{}.R.shape.gii".format(fname)])
subprocess.call(["rm", "{}.L.shape.gii".format(fname)])

