import pandas as pd
from joblib import Parallel, delayed
import os
import numpy as np

from paths import paths
from load_data import abccare

samples = pd.read_csv(paths.samples)
samples.index = range(samples.shape[0])
samples = samples.T
samples.index = pd.Index(range(samples.shape[0]), name='draw')

outcomes = pd.read_csv(os.path.join(paths.outcomes), index_col='variable')

attriters = [9999, 74, 78, 82, 900, 906, 912, 914, 922, 99, 119, 121]

crime_attrit = [9999, 70, 74, 75, 76, 78, 82, 900, 906,
                907, 909, 911, 912, 83, 87, 94, 97, 914,
                915, 921, 922, 99, 100, 102, 104, 105, 110,
                931, 934, 938, 941, 119, 120, 121, 126, 954]

# Define function to take difference across the treatment and control groups

def meandiff(indata, index, sex='pooled', verbose=False):
	np.random.seed(1234)
	output = pd.DataFrame(index=outcomes.index, 
		columns=pd.MultiIndex.from_product([['ipw', 'raw'], ['control', 'diff']]))
  	# choose subsamples of data (i.e. use the bootstrap indexes)
	try: 
		indata = indata.loc[index.dropna()].copy()
		indata.index = range(indata.shape[0])
		if sex == 'male':
			indata = indata.loc[indata.male==1, :]
		elif sex == 'female':
			indata = indata.loc[indata.male==0, :]
	# deal with bootstraps where bootstrap index may not apply (e.g. all index is for cohort 1, but sampele limited to cohort 2)   
	except:
		return output

	for v in outcomes.index:
		if verbose:
			print 'Effects for {}'.format(v)
		data = indata.copy()
		c = data.loc[data.R==0,v].mean()
		t = data.loc[data.R==1,v].mean()
		diff = t - c
		output.loc[v, ('raw', ['control', 'diff'])] = [c, diff]
	return output

# Define the function to generate the distributions for males, females, and pooled
def diff_by_sex(data, index, draw):
	pooled = meandiff(data, index=index,sex='pooled')
	male = meandiff(data, index=index, sex='male')
	female = meandiff(data, index=index, sex='female')

	output = pd.concat([pooled, male, female], axis=1, 
		keys=['pooled', 'male', 'female'], names=['sex'])

	print 'Bootstrap draw {} successful'.format(draw)
	return output

# Perform the bootstraps

'''
Cohort Number Definitions:
0. Full CARE sample
1. Cohort 1 (ABC)
2. Cohort 2 (ABC)
3. Cohort 3 (ABC)
4. Cohort 4 (ABC)
5. Cohort 5 (CARE)
6. Cohort 6 (CARE)
7. Crime Release Subjects (ABC and CARE)
8. Age 34 Health Subjects (ABC and CARE)
10. ABC Attriters (main sample)
11. ABC Post Attrition (main sample)
'''

for cohort in [0, 1, 2, 3, 4, 7, 8, 10, 11]:
    if cohort == 0:
        data = abccare
    if cohort in [1,2,3,4]:
        data = abccare.loc[abccare.cohort == cohort]
    if cohort == 7:
        data = abccare.drop(crime_attrit, axis=0)
    if cohort == 8:   
        data = abccare.loc[abccare.si34y_complete==1]
    if cohort == 10:
        data = abccare.copy()
        data.R= 0
        data.loc[attriters, 'R'] = 1
    if cohort == 11:
        data = abccare.drop(attriters, axis=0)
    
    rslt = Parallel(n_jobs=1)(
    	delayed(diff_by_sex)(data, s, i) for i,s in samples.iterrows())
    rslt = pd.concat(rslt, axis=0, keys=range(len(rslt)), names=['draw'])
    
    if cohort == 0:    
        rslt.to_pickle(os.path.join(paths.rslt, 'bootstrap_balance.pkl'))
    if cohort in [1,2,3,4]:
        rslt.to_pickle(os.path.join(paths.rslt, 'bootstrap_balance_coh{}.pkl'.format(cohort)))
    if cohort == 7:
        rslt.to_pickle(os.path.join(paths.rslt, 'bootstrap_balance_crime.pkl'))
    if cohort == 8:
        rslt.to_pickle(os.path.join(paths.rslt, 'bootstrap_balance_health.pkl'))
    if cohort == 10:
        rslt.to_pickle(os.path.join(paths.rslt, 'bootstrap_balance_attrition.pkl'))
    if cohort == 11:
        rslt.to_pickle(os.path.join(paths.rslt, 'bootstrap_balance_postattrition.pkl'))
