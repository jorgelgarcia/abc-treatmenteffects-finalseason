'''
Created on Mon Oct 05 12:06:42 2015

Setup module for ABC labor income imputations

Author: Jake C. Torcasso, Joshua Shea

Description: This file projects earnings of ABC subjects.
'''

import os
import sys
import pandas as pd
import statsmodels.api as sm
from patsy import dmatrices
import numpy as np
np.asinh = np.vectorize(np.math.asinh)
from math import isnan, sqrt
from copy import deepcopy
from pandas.io.stata import StataReader

from paths import paths
from load_data import abcd
from variables import cols

#----------------------------------------------------------------

# Save the index of people who you cannot estimate income for

#male_interp_nix = abcd.loc[abcd.male_subject==1].loc[pd.isnull(abcd.loc[abcd.male_subject==1, cols.interpABC.predictors]).any(axis=1)].index
#female_interp_nix = abcd.loc[abcd.male_subject==0].loc[pd.isnull(abcd.loc[abcd.male_subject==0, cols.interpABC.predictors]).any(axis=1)].index

male_extrap_nix = abcd.loc[abcd.male_subject==1].loc[pd.isnull(abcd.loc[abcd.male_subject==1, cols.extrap.predictors]).any(axis=1)].index
female_extrap_nix = abcd.loc[abcd.male_subject==0].loc[pd.isnull(abcd.loc[abcd.male_subject==0, cols.extrap.predictors]).any(axis=1)].index

#----------------------------------------------------------------

def predict_abc(extrap, extrap_index, abc, verbose=True):

	# set up age range
	ages = range(21, 65)

	# set up dictionaries to store output
	params_extrap = {}
	error_mat = {}

	# set up matrices for interpolation/extrapolation parameters, and errors
	for sex in ['pooled', 'male', 'female']:
		params_extrap[sex] = pd.DataFrame([[np.nan for j in range(len(cols.extrap.predictors) + 3)] for k in range(21,65)], index = range(21,65))
		params_extrap[sex].index.names = ['age']
		params_extrap[sex].columns = ['Intercept'] + cols.extrap.predictors + ['y'] + ['rmse']
		error_mat[sex] = pd.DataFrame([])

	# obtain parameters for every age
	for age in ages:
		age_x = age - 1
		predictors = cols.extrap.predictors + ['inc_labor{}'.format(age_x)]
				
		aux = deepcopy(extrap.loc[extrap_index, :])
		
		c = 'inc_labor{}'.format(age)

	# obtain parameters for different sexes
		for sex in ['pooled', 'male', 'female']:

			if sex == 'pooled':
				data = aux
				abcd = abc
				abcd_count = abcd.shape[0]
			elif sex == 'male':
				data = aux
				abcd = abc.loc[abc.male_subject==1]
				abcd_count = abcd.loc[abcd['male_subject']==1]['male_subject'].count()
			else:
				data = aux
				abcd = abc.loc[abc.male_subject==0]
				abcd_count = abcd.loc[abcd['male_subject']==0]['male_subject'].count()

			# reset auxiliary index because sm.OLS drops some rows
			data.reset_index('id', drop=True, inplace=True)
			data.index = [j for j in range(data.shape[0])]
			# create design matrix for regressions
			fmla = '{} ~ {}'.format(c, ' + '.join(predictors))
			endog, exog = dmatrices(fmla, data, return_type='dataframe')
			exog = sm.add_constant(exog)

			# estimate coefficients
			fail_switch = 0
			try:
				model = sm.OLS(endog, exog)
				fit = model.fit()
				params = fit.params
				resid = fit.resid
			except:
				fail_switch = 1

				params = pd.Series([np.nan for j in range(1 + len(predictors))], index=['Intercept'] + cols.extrap.predictors + ['y'])
				resid = pd.Series([np.nan for j in range(endog.shape[0])])
			
   			# calculate RMSE
   			rmse = resid * resid
   			rmse =  pd.Series(sqrt(rmse.mean(axis=0)), index=['rmse'])
   			params = pd.concat([params, rmse],axis=0)
			params.rename({'inc_labor{}'.format(age_x):'y'}, inplace=True)
			params_extrap[sex].loc[age, :] = params
   			# resample the errors, and merge in with ABC IDs
			if fail_switch == 0:
   				ehat = pd.DataFrame(np.random.choice(resid, size=abcd_count))
			else:
   				ehat = pd.DataFrame([np.nan for j in range(abcd_count)])
   			abcd_ix = abcd.reset_index(level=0)
   			ehat = pd.concat([abcd_ix.loc[:,'id'], ehat], axis=1)
   			ehat.columns = ['id', age]
   			ehat.columns.name = 'age'
   			ehat.set_index('id', inplace=True)
   			error_mat[sex] = pd.concat([error_mat[sex], ehat], axis=1)
			
		if verbose:
			print 'Successful predictions, age {}, n={}'.format(age, exog.shape[0])

   	# add treatment indicator back into error matrix, add column names
	treat = abc.loc[:,'R']
	for sex in ['pooled', 'male', 'female']:
		error_mat[sex] = pd.concat([error_mat[sex], treat], axis=1, join='inner')
		params_extrap[sex].columns.name = 'variable'

	# extrap (we only check age 31 since predicatablity of each year are based on the same set of outcomes)

	error_mat['male'].loc[male_extrap_nix, slice(9,45)] = np.nan
	error_mat['female'].loc[female_extrap_nix, slice(9,45)] = np.nan
	error_mat['pooled'].loc[female_extrap_nix.append(male_extrap_nix), slice(9,45)] = np.nan

	# predict earnings
	projection_extrap = {}
	abc.loc[:, 'Intercept'] = [1 for j in range(abc.shape[0])]

	for sex in ['pooled', 'male', 'female']:
	
		if sex == 'pooled':
			abcd = abc

		elif sex == 'male':
			abcd = abc.loc[abc.male_subject==1]

		else:
			abcd = abc.loc[abc.male_subject==0]

   		abcd_extrap = abcd.loc[:, ['Intercept'] + cols.extrap.predictors + ['y']]
		
		projection_extrap[sex] = pd.DataFrame([])

		for idx in abcd.iterrows():
			age_extrap = pd.DataFrame([np.nan for k in range(21,65)], index = range(21,65))
			age_extrap.index.names = ['age']
			tmp_age = idx[1].loc['last_age']

			if tmp_age < 21:
				tmp_age = 21
			for age in range(tmp_age, 65):
				params_extrap_trans = pd.DataFrame(params_extrap[sex].loc[age].drop('rmse').T)
				extrap_dot = abcd_extrap.loc[idx[0],:].dot(params_extrap_trans) + error_mat[sex][[age]].loc[idx[0],:]

				abcd_extrap.loc[idx[0],'y'] = extrap_dot.iloc[0]
				age_extrap[age] = extrap_dot.iloc[0]

			projection_extrap[sex] = pd.concat([projection_extrap[sex], age_extrap], axis=1)
			print projection_extrap[sex]

	return params_extrap, error_mat, projection_extrap


#----------------------------------------------------------------

if __name__ == '__main__':

	from load_data import extrap, interp, abcd

	np.random.seed(1234)

	aux_draw = 3

	# Bring in auxiliary data
	interp_index = pd.read_csv(paths.cnlsy_bsid)

	reader = StataReader(paths.psid_bsid)
	psid = reader.data(convert_dates=False, convert_categoricals=False)
	psid = psid.iloc[:,0:aux_draw] # limit PSID to the number of repetitions you need
	nlsy = pd.read_csv(paths.nlsy_bsid)

	interp_index = interp_index.iloc[:,0]  # use position 0 for full NLSY/CNLSY sample

	extrap_index = pd.concat([psid, nlsy], axis=0, keys=('psid', 'nlsy'), names=('dataset','id'))
	extrap_source= ['psid' for j in range(0, psid.shape[0])] + ['nlsy' for k in range(0, nlsy.shape[0])]

	extrap_draw = extrap_index.iloc[:,0]
	extrap_tuples = list(zip(*[extrap_source,extrap_draw]))
	for i in xrange(len(extrap_tuples) - 1, -1, -1):
		if isnan(extrap_tuples[i][1]):
			del extrap_tuples[i]

	extrap_ind = pd.MultiIndex.from_tuples(extrap_tuples, names=['dataset','id'])   # use position 0 for full PSID sample

	tmp = extrap.index.isin(extrap_ind)
	tmp = extrap[tmp].index
	tmp = extrap_ind.isin(tmp)
	extrap_index = extrap_ind[tmp]

	params_interp, params_extrap, errors, proj_interp, proj_extrap = predict_abc(interp, extrap, interp_index=interp_index, extrap_index=extrap_index, abc = abcd, verbose=True)
