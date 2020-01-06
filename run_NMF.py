import numpy as np
from scipy import sparse
from numpy import array, matrix
from sklearn.decomposition import NMF as nmf
import sys

results_dir="/gpfs01/home/ppxet1/tests/imgvolta2/"

cm_path="/share/neurodev/matrix2/Results/NMF_paper/average_cm.npz"

num_components = 100

#regularisation parameters
alpha=0.1
l1_ratio=1

#load connectivity matrix
x = sparse.load_npz(cm_path)
connectivity_matrix = x.toarray()
print "loaded data"

#apply NMF to connectivity matrix
model = nmf(n_components=num_components, alpha=alpha, l1_ratio=l1_ratio, random_state=1)
W = model.fit_transform(connectivity_matrix)
H = model.components_

#save results
np.save("{}{}_NMFmm.npy".format(results_dir, num_components), H)
np.save("{}{}_NMFcomps.npy".format(results_dir, num_components), W)
