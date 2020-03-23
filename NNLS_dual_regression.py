import numpy as np
from numpy import array, matrix
from scipy import sparse
import sklearn
import sys
import re
import scipy
from scipy.optimize import nnls
from multiprocessing import Pool
import time

def nnls_func(p):
    comp, rnorm = nnls(p[0], p[1])
    return comp

#path to group level grey matter components
group_gm_path= sys.argv[1]

#path to subject (or different group) level connectivity matrix, stored in .npz format
subj_cmat_path = sys.argv[2]

#output path 
results_path = sys.argv[3] 

#number of cores to use
n_cores = int(sys.argv[4])

########################
chunksize=5
start = time.time()
#load in group data
group_gm = np.load(group_gm_path)
n_comp = group_gm.shape[1]

print "PARALLELISED, number of cores = {}, number of components = {}, chunksize = {}".format(n_cores, n_comp, chunksize)

#load connectivity matrix
print "preparing data"
x = sparse.load_npz(subj_cmat_path)
connectivity_matrix = x.toarray()
n_vertices, n_voxels = np.shape(connectivity_matrix)

#normalise by waytotal
#waytotal_file = subj_dir + "/waytotal"
#w = open(waytotal_file, "r")
#waytotal = w.readline()
#waytotal = int(waytotal.rstrip())
#connectivity_matrix = (1e8)*connectivity_matrix/waytotal
end = time.time()

print("time taken to load data = %s" % (end - start))
             
#project group_data onto connectivity matrix
print "calulating subject specific tract components"
start=time.time()
tract_comp = np.zeros((n_comp, n_voxels))
inputlist = [[group_gm, connectivity_matrix[:,i]] for i in range(n_voxels)]

p= Pool(processes=n_cores)
tract_list = p.imap(nnls_func, inputlist, chunksize=chunksize)
tract_list = list(tract_list)

for i in range(n_voxels):
    tract_comp[:,i] = tract_list[i]
end = time.time()

print("time taken to generate wm components = %s" % (end - start))

#find subject-specific mixing matrix
print "calculating subject specific surface components"
start = time.time()
surf_comp = np.zeros((n_comp, n_vertices))
inputlist = [[tract_comp.T, connectivity_matrix.T[:,j]] for j in range(n_vertices)]
surf_list = p.imap(nnls_func, inputlist, chunksize=chunksize)

p.close()
p.join()
surf_list = list(surf_list)
for i in range(n_vertices):
    surf_comp[:,i] = surf_list[i]
surf_comp = surf_comp.T

end = time.time()
print("time taken to generate gm components = %s" % (end - start))

#save as numpy array
np.save("{}_gm.npy".format(results_path), surf_comp)
np.save("{}_wm.npy".format(results_path), tract_comp)

