import numpy as np
from scipy import sparse
from numpy import array, matrix
from sklearn.decomposition import NMF as nmf
import sys

#path to connectivity matrix
cm_path = sys.argv[1]

#where you want to save the results
results_dir= sys.argv[2]

#model order for the decomposition
num_components = int(sys.argv[3])

#regularisation parameters
alpha=0.1
l1_ratio=1

#load connectivity matrix
x = sparse.load_npz(cm_path)
connectivity_matrix = x.toarray()
print "loaded data"

#apply NMF to connectivity matrix
model = nmf(n_components=num_components, alpha=alpha, l1_ratio=l1_ratio, init="nndsvd", random_state=1)
W = model.fit_transform(connectivity_matrix)
H = model.components_

#save results
np.save("{}/{}_wm_NMF.npy".format(results_dir, num_components), H)
np.save("{}/{}_gm_NMF.npy".format(results_dir, num_components), W)
