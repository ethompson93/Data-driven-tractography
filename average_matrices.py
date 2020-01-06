import numpy as np
from scipy import sparse
import pandas as pd


#directory where subject data is stored
data_dir = "/share/neurodev/matrix2/"

#directory where average matrix is to be saved
results_dir = "/share/neurodev/matrix2/Results/NMF_paper/classifier/" 

#list of subjects, in csv file with headings including "subID" and "sesID", for subject ID and session ID respectively
subject_list="/gpfs01/home/ppxet1/scripts/NMF_paper/all_subjects.csv".format(split)

df = pd.read_csv(subject_list)

n=0.0

for subject, session in zip(df.subID, df.sesID):
	print(subject, session)

	#load in subject data
	f = "{}{}/ses-{}/".format(data_dir, subject, session)
	cm = sparse.load_npz(f + "fdt_matrix2.npz")
	
	#convert to compressed sparse row format for faster processing
	cm_csr = cm.tocsr()
	
	#extract number of valid streamlines from Fdt output
	waytotal_file = f + "waytotal"
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
sparse.save_npz(results_dir + "average_cm", average_cm.tocoo())
