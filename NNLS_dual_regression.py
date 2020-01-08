import numpy as np
from numpy import array, matrix
from scipy import sparse
import sklearn
import sys
import re
import scipy
from scipy.optimize import nnls

#path to group level grey matter components
group_gm_path= sys.argv[1]

#directory where subject data are stored (in format data_dir/subID/sesID/...)
data_dir = sys.argv[2]

#subject and session IDs
subject = sys.argv[3]
session = sys.argv[4]

subj_dir = "{}/{}/{}".format(data_dir, subject, session)

#directory where you want results to be stored
results_dir = sys.argv[5] 


#load in group data
group_gm = np.load(group_gm_path)
n_comp = group_gm.shape[1]

#load connectivity matrix
print "preparing data"
cmat = "{}/fdt_matrix2.npz".format(subj_dir)
x = sparse.load_npz(cmat)
connectivity_matrix = x.toarray()
n_vertices, n_voxels = np.shape(connectivity_matrix)

#normalise by waytotal
waytotal_file = subj_dir + "/waytotal"
w = open(waytotal_file, "r")
waytotal = w.readline()
waytotal = int(waytotal.rstrip())
connectivity_matrix = (1e8)*connectivity_matrix/waytotal

             
#project group_data onto connectivity matrix
print "calulating subject specific tract components"
tract_comp = np.zeros((n_comp, n_voxels))
for i in range(n_voxels):
	tract_comp[:, i], rnorm = nnls(group_gm, connectivity_matrix[:,i])


#find subject-specific mixing matrix
print "calculating subject specific surface components"
surf_comp = np.zeros((n_comp, n_vertices))
for j in range(n_vertices):
	surf_comp[:,j], rnorm = nnls(tract_comp.T, connectivity_matrix.T[:,j])
surf_comp = surf_comp.T

#save as numpy array
np.save("{}/{}_{}_{}_gm_NMF.npy".format(results_dir,  subject, session, n_comp), surf_comp)
np.save("{}/{}_{}_{}_wm_NMF.npy".format(results_dir, subject, session,  n_comp), tract_comp)

