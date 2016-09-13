# -*- coding: utf-8 -*-
'''
Created on Tue Oct 06 17:02:19 2015

@author: Joshua
Description: this script estimates the labor income for ABC subjects
for multiple bootstraps of the auxiliary data.
'''

import os
import sys
from joblib import Parallel, delayed
import pandas as pd
from pandas.io.stata import StataReader
from math import isnan

from setup_prediction_lag import predict_abc
from load_data import interp, extrap, abcd

sys.path.extend([os.path.join(os.path.dirname(__file__), '..')])
from paths import paths

#----------------------------------------------------------------

seed = 1234
aux_draw = 1000

#----------------------------------------------------------------

# bring in file with indexes for interpolation bootstrap
interp_index = pd.read_csv(paths.cnlsy_bsid)

# bring in file with indexes for extrapolation bootstrap
reader = StataReader(paths.psid_bsid)
psid = reader.data(convert_dates=False, convert_categoricals=False)
psid = psid.iloc[:,0:aux_draw] # limit PSID to the number of repetitions you need
nlsy = pd.read_csv(paths.nlsy_bsid)

# set up extrapolation indexes (there are multiple data sets)
extrap_index = pd.concat([psid, nlsy], axis=0, keys=('psid', 'nlsy'), names=('dataset','id'))
extrap_source= ['psid' for j in range(0, psid.shape[0])] + ['nlsy' for k in range(0, nlsy.shape[0])]

assert interp_index.shape[1] == extrap_index.shape[1]

#----------------------------------------------------------------

def boot_predict_aux(interp, extrap, adraw):

	# prepare indexes of interpolation data for bootstrap
	interp_ind = interp_index.loc[:, 'draw{}'.format(adraw)].dropna()

	# prepare indexes of extrapolation data for bootstrap
	extrap_draw = extrap_index.loc[:, 'draw{}'.format(adraw)]
	extrap_tuples = list(zip(*[extrap_source,extrap_draw]))
	for i in xrange(len(extrap_tuples) - 1, -1, -1):
		if isnan(extrap_tuples[i][1]):
			del extrap_tuples[i]
	extrap_ind = pd.MultiIndex.from_tuples(extrap_tuples, names=['dataset','id'])

	# deal with the fact that USC did alternative bootstrap method
	# their bootstrap samples include observations you don't have
	# so only keep the ones that you do have
	tmp = extrap.index.isin(extrap_ind)
	tmp = extrap[tmp].index
	tmp = extrap_ind.isin(tmp)
 	extrap_ind = extrap_ind[tmp]

	# now estimate the earnings
	params_interp, params_extrap, errors, proj_interp, proj_extrap = predict_abc(interp, extrap, interp_index=interp_ind, extrap_index=extrap_ind, abc = abcd, verbose=True)

	print 'Success auxiliary bootstrap {}.'.format(adraw)

	output = [params_interp, params_extrap, errors, proj_interp, proj_extrap]

	return output

#----------------------------------------------------------------

# run estimates
rslt = Parallel(n_jobs=1)(
	delayed(boot_predict_aux)(interp, extrap, k) for k in xrange(aux_draw))

params_interp = {}
params_extrap = {}
errors = {}
projections = {}

#----------------------------------------------------------------

# output results

for sex in ['male', 'female', 'pooled']:

	params_interp[sex] = pd.concat([rslt[k][0][sex] for k in range(aux_draw)], axis=0, keys=range(aux_draw), names=['adraw'])
 	params_extrap[sex] = pd.concat([rslt[k][1][sex] for k in range(aux_draw)], axis=0, keys=range(aux_draw), names=['adraw'])
 	errors[sex] = pd.concat([rslt[k][2][sex] for k in range(aux_draw)], axis=0, keys=range(aux_draw), names=['adraw'])
   	projections[sex] = pd.concat([pd.concat([rslt[k][3][sex], rslt[k][4][sex]], axis=1) for k in range(aux_draw)], axis=0, keys=range(aux_draw), names=['adraw'])

	'''
 	# We only need to output the projections
   	# output parameters and errors as pickles
   	params_interp[sex].to_pickle(os.path.join(paths.rslts, 'labor_interp_params_{}.pkl'.format(sex)))
   	params_extrap[sex].to_pickle(os.path.join(paths.rslts, 'labor_extrap_params_{}.pkl'.format(sex)))
   	errors[sex].to_pickle(os.path.join(paths.rslts, 'labor_errors_{}.pkl'.format(sex)))
   	'''

   	# output projections .csv
   	projections[sex].to_csv(os.path.join(paths.rslts, 'labor_proj_{}.csv'.format(sex)))
