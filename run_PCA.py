import numpy as np
from scipy import sparse
from numpy import array, matrix
import sys

#path to group level connectivity matrix
cm_path = sys.argv[1]

#where you want to save the components
output_filename = sys.argv[2]

#number of principal components to use
dPCA = int(sys.argv[3])

def run_PCA(connectivity_matrix, dPCA) :
    
    from sklearn.decomposition import PCA

    pca = PCA(n_components=dPCA, random_state=1)
    PCs = pca.fit_transform(connectivity_matrix)

    #variance explained by all the components, as a percentage of the total    
    explained_variance =  100*np.cumsum(pca.explained_variance_ratio_)[dPCA -1]

    return PCs, explained_variance



x = sparse.load_npz(cm_path)
connectivity_matrix = x.toarray()

PCs, explained_variance = run_PCA(connectivity_matrix, dPCA)

print("{} components, variance explained = {}".format(dPCA, explained_variance))
np.save(output_filename, PCs)

