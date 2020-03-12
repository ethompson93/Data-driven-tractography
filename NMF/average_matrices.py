import numpy as np
from scipy import sparse
import pandas as pd
import sys

#list of subjects, in csv file with headings including "subID" and "sesID", for subject ID and session ID respectively
subject_list=sys.argv[1]

#directory where subject data is stored (in format data_dir/subID/sesID/...)
data_dir = sys.argv[2]

#path and name for the output file
output_filename = sys.argv[3]

df = open(subject_list, "r")

n=0.0

for subject in df:
	outlog = open("{}.txt".format(output_filename),"a+")
	outlog.write(str(subject))
	outlog.write("\n")
	outlog.close()

	#load in subject data
	f = "{}/{}/MNINonLinear/Results/Tractography_NMF".format(data_dir, subject.rstrip())
	cm = sparse.load_npz(f + "/fdt_matrix2.npz")

	#convert to compressed sparse row format for faster processing
	cm_csr = cm.tocsr()

	#extract number of valid streamlines from Fdt output
	waytotal_file = f + "/waytotal"
	w = open(waytotal_file, "r")
	waytotal = w.readline()
	waytotal = float(waytotal.rstrip())

	#initialise average matrix from first dataset
	if n == 0:
		average_cm = cm_csr.multiply(1e8/waytotal)
	else:
	#normalise each connectivity matrix by number of valid streamlines
		average_cm += (cm_csr.multiply(1e8/waytotal))

	n+=1

average_cm = average_cm.multiply(1/n)
average_cm_coo = average_cm.tocoo()
sparse.save_npz(output_filename, average_cm.tocoo())
