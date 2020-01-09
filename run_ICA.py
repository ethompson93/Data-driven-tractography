import numpy as np
from scipy import sparse
from numpy import array, matrix
from sklearn.decomposition import FastICA
import sys

#path to principal components
pca_path=sys.argv[1]

#path to connectivity matrix
cm_path=sys.argv[2]

#where you want to save the results
output_filename=sys.argv[3]

#model order for the decomposition
num_components = int(sys.argv[4])


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

gm_ICs, wm_ICs = run_ICA(PCs, connectivity_matrix, num_components)

np.save("{}_gm".format(output_filename), gm_ICs)
np.save("{}_wm".format(output_filename), wm_ICs)
