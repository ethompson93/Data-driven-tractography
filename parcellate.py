import numpy as np
from sklearn.preprocessing import StandardScaler
import sys

#components used to generate parcellation
component_path=sys.argv[1]

#path and name for the output file
output_filename = sys.argv[2]


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


#load components and generate parcellation
components = np.load(component_path)
parcellation = parcellate(components)

#save parcellations
np.save(output_filename, parcellation)

