import numpy as np
from sklearn.preprocessing import StandardScaler

def parcellate(components):
    #scale components before parcellation
    scaler = StandardScaler() 
    comps_scaled = scaler.fit_transform(components)
    n_seeds = np.shape(components)[0]
    parcellation = np.zeros([n_seeds,1])
    #label vertices according to highest weighted components
    for row in range(0, n_seeds):
        parcellation[row] = np.where(comps_scaled[row, :] == np.max(comps_scaled[row, :]))

    parcellation = parcellation + 1

    return parcellation

#where you want to save parcellation
results_dir = "/gpfs01/home/ppxet1/tests/pipeline_output/"

#components used to generate parcellation
component_path="/share/neurodev/matrix2/Results/NMF_paper/NMF/200_W_split1.npy"



#load components and generate parcellation
components = np.load(component_path)
parcellation = parcellate(components)

#save parcellations
np.save("{}parcellation.npy".format(results_dir), parcellation)

