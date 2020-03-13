# Data-driven-tractography
This repository contains scripts to perform data-driven mapping of white matter bundles and corresponding grey matter networks from whole brain tractography data, as descibed in this pre-print: [Non-Negative Data-Driven Mapping of Structural Connections in the Neonatal Brain; E. Thompson, A.R. Mohammadi-Nejad, E.C. Robinson, M.F. Glasser, S. Jbabdi, M. Bastiani, S.N. Sotiropoulos (2020)](https://www.biorxiv.org/content/10.1101/2020.03.09.965079v1). 

## Code Overview
- pre_mat2.sh, run_mat2.sh and post_mat2.sh contain scripts to generate a grey matter to whole brain connectivity matrices, using probabilistic tractography (matrix2 in FSL). 
- dot2npz.py converts the sparse .dot files output from probtrackx to numpy's sparse format .npz, so that they can be manipulated in python.
- the .npz files can then be averaged using average_matrices.py
- run_PCA.py, run_ICA.py and run_NMF.py are used to run decompositions on the connectivity matrices
- the output .npy files from the decompositions can be converted into cifti (grey matter) and nifti (white matter) formats using npy2cifti.py and npy2nifti.py, respectively
- parcellate.py generates hard cortical parcellations based on the grey matter components
- NNLS_dual_regression.py can be used to generate subject-level representations of the group level components

## Usage
- An example pipeline is given in example_pipeline.sh
- The scripts were written based on data from the developing Human Connectome Project (http://www.developingconnectome.org), and so many require inputs of a subject and session ID to locate files because of the way the dHCP data are organised. A separate branch is being developed without the session IDs and some other features that are tailored to data from the young adult HCP (thanks [Shaun](https://github.com/swarrington1))


## Requirements
- FSL is required for the tractography (ideally with GPUs for speed)
- Python scripts run in Python 2.7


