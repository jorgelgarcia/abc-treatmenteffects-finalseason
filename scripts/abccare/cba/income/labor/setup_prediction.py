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

sys.path.extend([os.path.join(os.path.dirname(__file__), '..')])
from paths import paths
from load_data import abcd
from variables import cols

#----------------------------------------------------------------

# Save the index of people who you cannot estimate income for
male_interp_nix = abcd.loc[abcd.male==1].loc[pd.isnull(abcd.loc[abcd.male==1, cols.interp.predictors]).any(axis=1)].index
female_interp_nix = abcd.loc[abcd.male==0].loc[pd.isnull(abcd.loc[abcd.male==0, cols.interp.predictors]).any(axis=1)].index

male_extrap_nix = abcd.loc[abcd.male==1].loc[pd.isnull(abcd.loc[abcd.male==1, cols.extrap.predictors]).any(axis=1)].index
female_extrap_nix = abcd.loc[abcd.male==0].loc[pd.isnull(abcd.loc[abcd.male==0, cols.extrap.predictors]).any(axis=1)].index

#----------------------------------------------------------------

def predict_abc(interp, extrap, interp_index, extrap_index, abc, verbose=True):

	# set up age range
	ages = range(22, 30) + range(31, 68)

	# set up dictionaries to store output
	params_interp = {}
	params_extrap = {}
	error_mat = {}

	# set up matrices for interpolation/extrapolation parameters, and errors
	for sex in ['pooled', 'male', 'female']:
		params_interp[sex] = pd.DataFrame([[np.nan for j in range(len(cols.interp.predictors) + 2)] for k in range(22,30)], index = range(22,30))
		params_interp[sex].index.names = ['age']
		params_interp[sex].columns = ['Intercept'] + cols.interp.predictors + ['rmse']

		params_extrap[sex] = pd.DataFrame([[np.nan for j in range(len(cols.extrap.predictors) + 2)] for k in range(31,68)], index = range(31,68))
		params_extrap[sex].index.names = ['age']
		params_extrap[sex].columns = ['Intercept'] + cols.extrap.predictors + ['rmse']

		error_mat[sex] = pd.DataFrame([])


	# obtain parameters for every age
	for age in ages:

		if age in range(22, 30):
			predictors = cols.interp.predictors
			aux = deepcopy(interp.loc[interp_index, :])

		elif age in range(31, 68):
			predictors = cols.extrap.predictors
			aux = deepcopy(extrap.loc[extrap_index, :])

		c = 'inc_labor{}'.format(age)

		# obtain parameters for different sexes
		for sex in ['pooled', 'male', 'female']:

			if sex == 'pooled':
				data = aux
				abcd = abc
				abcd_count = abcd.shape[0]

			elif sex == 'male':
				data = aux.loc[aux.male==1]
				abcd = abc.loc[abc.male==1]
				abcd_count = abcd.loc[abcd['male']==1]['male'].count()
			else:
				data = aux.loc[aux.male==0]
				abcd = abc.loc[abc.male==0]
				abcd_count = abcd.loc[abcd['male']==0]['male'].count()

			# reset auxiliary index (why?)
			data.reset_index('id', drop=True, inplace=True)
			data.index = [j for j in range(data.shape[0])]

			# create design matrix for regressions
			fmla = '{} ~ {}'.format(c, ' + '.join(predictors))
			endog, exog = dmatrices(fmla, data, return_type='dataframe')
			exog = sm.add_constant(exog)
			
			print "exog"
			print exog

			# estimate coefficients
			fail_switch = 0
			try:
				model = sm.OLS(endog, exog)
				fit = model.fit()
				params = fit.params
				resid = fit.resid
			except:
				fail_switch = 1
				params = pd.Series([np.nan for j in range(1 + len(predictors))], index=['Intercept'] + predictors)
				resid = pd.Series([np.nan for j in range(endog.shape[0])])

   			# calculate RMSE
   			rmse = resid * resid
   			rmse =  pd.Series(sqrt(rmse.mean(axis=0)), index=['rmse'])
   			params = pd.concat([params, rmse],axis=0)

   			if age in range(22,30):
				params_interp[sex].loc[age, :] = params

   			else:
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
		params_interp[sex].columns.name = 'variable'
		params_extrap[sex].columns.name = 'variable'

	# remove errors for ABC individuals for whom we do not predict earnings
	# interp (we only check age 22 since predicatablity of each year are based on the same set of outcomes)

	error_mat['male'].loc[male_interp_nix, slice(0,8)] = np.nan
	error_mat['female'].loc[female_interp_nix, slice(0,8)] = np.nan
	error_mat['pooled'].loc[female_interp_nix.append(male_interp_nix), slice(0,8)] = np.nan
	# extrap (we only check age 31 since predicatablity of each year are based on the same set of outcomes)

	error_mat['male'].loc[male_extrap_nix, slice(9,45)] = np.nan
	error_mat['female'].loc[female_extrap_nix, slice(9,45)] = np.nan
	error_mat['pooled'].loc[female_extrap_nix.append(male_extrap_nix), slice(9,45)] = np.nan

	# predict earnings
	projection_interp = {}
	projection_extrap = {}
	abc.loc[:, 'Intercept'] = [1 for j in range(abc.shape[0])]
	for sex in ['pooled', 'male', 'female']:

		if sex == 'pooled':
			abcd = abc
			abcd_interp = abcd.loc[:, ['Intercept'] + cols.interp.predictors]
   			abcd_extrap = abcd.loc[:, ['Intercept'] + cols.extrap.predictors]

		elif sex == 'male':
			abcd = abc.loc[abc.male==1]
			abcd_interp = abcd.loc[:, ['Intercept'] + cols.interp.predictors]
   			abcd_extrap = abcd.loc[:, ['Intercept'] + cols.extrap.predictors]

		else:
			abcd = abc.loc[abc.male==0]
			abcd_interp = abcd.loc[:, ['Intercept'] + cols.interp.predictors]
   			abcd_extrap = abcd.loc[:, ['Intercept'] + cols.extrap.predictors]

		# peform projetions using dot product, add back in the errors
		projection_interp[sex] = abcd_interp.dot(params_interp[sex].drop('rmse', axis=1).T) + error_mat[sex].drop('R', axis=1).loc[:,slice(22,29)]
		projection_extrap[sex] = abcd_extrap.dot(params_extrap[sex].drop('rmse', axis=1).T) + error_mat[sex].drop('R', axis=1).loc[:,slice(31,67)]
	return params_interp, params_extrap, error_mat, projection_interp, projection_extrap


#----------------------------------------------------------------

if __name__ == '__main__':

	from load_data import extrap, interp, abcd

	np.random.seed(1234)

	aux_draw = 50

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
