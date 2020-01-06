import numpy as np
from scipy import sparse
from numpy import array, matrix
from sklearn.decomposition import FastICA
import sys

#path to principal components
pca_path="/share/neurodev/matrix2/Results/NMF_paper/ICA/500_PCs.npy"

#where you want to save the results
results_dir="/home/ppxet1/tests/imgvolta2/"

#path to connectivity matrix
cm_path="/share/neurodev/matrix2/Results/NMF_paper/average_cm.npz"

num_components = 100


def run_ICA(PCs, connectivity_matrix, num_components) :
    
    ica = FastICA(n_components=num_components,random_state=1)
    gm_ICs= ica.fit_transform(PCs)
    print 'resultant shape from ICA is {}'.format(np.shape(gm_ICs))
    
    #force the ICs to be positive on the long tail
    for i in range(0, num_components) :
        if np.percentile(gm_ICs[:,i],0.5) + np.percentile(gm_ICs[:,i],99.5) < 0 :
            gm_ICs[:,i] = gm_ICs[:,i]*-1
            
   
    # project into tract space
    invICs = np.linalg.pinv(gm_ICs)
    wm_ICs = np.dot(invICs, connectivity_matrix)

   
    return gm_ICs, wm_ICs


#load principal components and connectivity matrix
PCs = np.load(pca_path)
x = sparse.load_npz(cm_path)
connectivity_matrix = x.toarray()
print "loaded data"

mixing_matrix, ICs = run_ICA(PCs, connectivity_matrix, num_components)

np.save("{}{}_ICs.npy".format(results_dir, num_components), ICs)
np.save("{}{}_MM.npy".format(results_dir, num_components), mixing_matrix)
