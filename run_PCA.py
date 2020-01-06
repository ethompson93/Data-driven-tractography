import numpy as np
from scipy import sparse
from numpy import array, matrix
import sys


dPCA = 500
cm_path = "/share/neurodev/matrix2/Results/NMF_paper/classifier/average_cm.npz"
results_dir = "/share/neurodev/matrix2/Results/NMF_paper/classifier/" 

def run_PCA(connectivity_matrix, dPCA) :
    
    from sklearn.decomposition import PCA

    pca = PCA(n_components=dPCA)
    PCs = pca.fit_transform(connectivity_matrix)
    
    explained_variance =  100*np.cumsum(pca.explained_variance_ratio_)[dPCA -1]

    return PCs, explained_variance



x = sparse.load_npz(cm_path)
connectivity_matrix = x.toarray()

PCs, explained_variance = run_PCA(connectivity_matrix, dPCA)

print("{} components, variance explained = {}".format(dPCA, explained_variance))
np.save("{}{}_PCs.npy".format(results_dir, dPCA), PCs)

