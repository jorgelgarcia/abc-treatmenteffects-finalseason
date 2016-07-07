import os
import sys
import pandas as pd

sys.path.extend([os.path.join(os.path.dirname(__file__), 'labor')])
sys.path.extend([os.path.join(os.path.dirname(__file__), '..','..','sampling')])
from sampler import draw_index
from load_data import psid, cnlsy, nlsy

''' 
Sampling Parameters 
-------------------
seed : int
	seed for pseudo-random number generator
draws : int
	number of bootstrap draws
by : list or None
	if list, list of column names to stratify sampling
'''

seed = 1234
draws = 75
by = None

interp_baseline = ['male', 'black', 'm_ed0y']
interp_outcomes = ['si21y_inc_labor', 'si30y_inc_labor', 'years_30y', 'piatmath', 'si34y_bmi']
interp_predictors = interp_baseline + interp_outcomes

extrap_baseline = ['male', 'black']
extrap_outcomes = ['years_30y', 'si30y_inc_labor']
extrap_predictors = extrap_baseline + extrap_outcomes


# USC provides the bootstrap for PSID
psid = psid.dropna(subset=extrap_predictors)
samples = draw_index(psid, size=draws, by=by, seed=seed)
samples = pd.DataFrame(samples, index=['draw{}'.format(i) for i in xrange(draws)])
samples = samples.T
samples.to_csv('samples_psid.csv', header=True, index=False)

cnlsy = cnlsy.dropna(subset=interp_predictors)
samples = draw_index(cnlsy, size=draws, by=by, seed=seed)
samples = pd.DataFrame(samples, index=['draw{}'.format(i) for i in xrange(draws)])
samples = samples.T
samples.to_csv('samples_cnlsy.csv', header=True, index=False)

nlsy = nlsy.dropna(subset=extrap_predictors)
samples = draw_index(nlsy, size=draws, by=by, seed=seed)
samples = pd.DataFrame(samples, index=['draw{}'.format(i) for i in xrange(draws)])
samples = samples.T
samples.to_csv('samples_nlsy.csv', header=True, index=False)
