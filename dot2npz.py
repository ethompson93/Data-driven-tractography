import numpy as np
from numpy import array, matrix
from scipy import sparse
import gzip
import sys
filename = sys.argv[1]
#results_dir = sys.argv[2]
def dot2npz(filename):

	new_filename = filename + '.npz'

	f = gzip.GzipFile(filename + '.dot.gz', "r")
	
	x = np.loadtxt(f)
	print x[-1,0]
	n_seed=x[-1,0]
	n_target=x[-1,1]

	row=x[:-1,0]-1
	col=x[:-1,1]-1
	data=x[:-1,2]

	connectivity_matrix = sparse.coo_matrix((data, (row, col)), shape=(n_seed.astype(int), n_target.astype(int)))
	
	sparse.save_npz(new_filename, connectivity_matrix)

dot2npz(filename)


