import numpy as np
from scipy import sparse
import pandas as pd
import sys
import os

#directory where nm data is stored (in format data_dir/subID/sesID/...)
data_dir = sys.argv[1]

#path and name for the output file
output_filename = sys.argv[2]

n=0.0

for nm in os.listdir(data_dir):
	if nm.endswith(".npz"):
		outlog = open("{}.txt".format(output_filename),"a+")
		outlog.write(str(nm))
		outlog.write("\n")
		outlog.close()

		#load in nm data
		f = "{}/{}".format(data_dir, nm)
		cm = sparse.load_npz(f)

		#convert to compressed sparse row format for faster processing
		cm_csr = cm.tocsr()

		#extract number of valid streamlines from Fdt output - don't need for final averaging
		#waytotal_file = f + "/waytotal"
		#w = open(waytotal_file, "r")
		#waytotal = w.readline()
		#waytotal = float(waytotal.rstrip())

		#initialise average matrix from first dataset
		if n == 0:
			average_cm = cm_csr#.multiply(1e8/waytotal)
		else:
		#normalise each connectivity matrix by number of valid streamlines
			average_cm += (cm_csr)#.multiply(1e8/waytotal))

		n+=1

average_cm = average_cm.multiply(1/n)
average_cm_coo = average_cm.tocoo()
sparse.save_npz(output_filename, average_cm.tocoo())
