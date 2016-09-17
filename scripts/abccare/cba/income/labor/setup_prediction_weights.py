'''
Created on Mon Oct 05 12:06:42 2015

Setup module for ABC labor income imputations

Author: Jake C. Torcasso, Joshua Shea, Anna Ziff

Description: This file projects earnings of ABC subjects.

1: lag, X, W (1)
2: X, W (2)
3: lag, X
4: lag, W (3)
5: W (4)
6: X (5)

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

#wtabc_allids_c3_control wtabc_allids_c3_treat wtabc_allids_c3_full wtabc_allids_c2_control wtabc_allids_c2_treat wtabc_allids_c2_full wtabc_allids_c1_control wtabc_allids_c1_treat wtabc_allids_c1_full


#----------------------------------------------------------------

# Save the index of people who you cannot estimate income for
#male_interp_nix = abcd.loc[abcd.male==1].loc[pd.isnull(abcd.loc[abcd.male==1, cols.interp.predictors]).any(axis=1)].index
#female_interp_nix = abcd.loc[abcd.male==0].loc[pd.isnull(abcd.loc[abcd.male==0, cols.interp.predictors]).any(axis=1)].index

#male_extrap_nix = abcd.loc[abcd.male==1].loc[pd.isnull(abcd.loc[abcd.male==1, cols.extrap.predictors]).any(axis=1)].index
#female_extrap_nix = abcd.loc[abcd.male==0].loc[pd.isnull(abcd.loc[abcd.male==0, cols.extrap.predictors]).any(axis=1)].index

#----------------------------------------------------------------

def predict_abc(interp, extrap, interp_index, extrap_index, weight, interp_weights, extrap_weights, cs, abc, verbose=True):

	# set up age range
	ages = range(22, 30) + range(31, 68)

	# set up dictionaries to store output
	params_interp = {}
	params_extrap = {}
	error_mat = {}

	# set up matrices for interpolation/extrapolation parameters, and errors
	for sex in ['pooled', 'male', 'female']:
		params_interp[sex] = pd.DataFrame([[np.nan for j in range(len(cols.interp.predictors) + 3)] for k in range(22,30)], index = range(22,30))
		params_interp[sex].index.names = ['age']
		params_interp[sex].columns = ['Intercept'] + cols.interp.predictors + ['y'] + ['rmse']

		params_extrap[sex] = pd.DataFrame([[np.nan for j in range(len(cols.extrap.predictors) + 3)] for k in range(31,68)], index = range(31,68))
		params_extrap[sex].index.names = ['age']
		params_extrap[sex].columns = ['Intercept'] + cols.extrap.predictors + ['y'] + ['rmse']
		error_mat[sex] = pd.DataFrame([])
	
	# obtain parameters for every age
	for age in ages:
			
		if age in range(22, 30):
			aux = deepcopy(interp.loc[interp_index, :])
			if age == 22:

				interp_weights.reset_index(inplace=True)
				del interp_weights['draw']
				interp_weights.set_index('id', inplace=True, drop=True)
				weight_array = deepcopy(interp_weights.loc[pd.IndexSlice[interp_index],:])

			age_x = age - 1
			predictors = cols.interp.predictors + ['inc_labor{}'.format(age_x)]


		elif age in range(31, 68):
			aux = deepcopy(extrap.loc[extrap_index, :])
			if age == 31:
				age_x = 29
				predictors = cols.extrap.predictors + ['inc_labor{}'.format(age_x)]

			else: 
				age_x = age - 1
				predictors = cols.extrap.predictors + ['inc_labor{}'.format(age_x)]
			
			
			
			if age == 31:
				extrap_index_weight = [x[1] for x in extrap_index]

				extrap_weights.reset_index(inplace=True)
				del extrap_weights['draw']
				extrap_weights.set_index('id', inplace=True, drop=True)
				weight_array = deepcopy(extrap_weights.loc[extrap_index_weight,:])

		c = 'inc_labor{}'.format(age)

		# drop black
		# drop black
		aux = aux.loc[aux.black == 1]

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
		
			if weight == 'treat':
				abcd = abcd.loc[abcd.R==1]
			elif weight == 'control':
				abcd = abcd.loc[abcd.R==0]
			
			# reset auxiliary index (because dmatrices won't use id)
			data.reset_index('id', drop=True, inplace=True)
			data.index = [j for j in range(data.shape[0])]
			
			weight_array.reset_index('id', drop=True, inplace=True)
			weight_array.index = [j for j in range(weight_array.shape[0])]

			#weight_array = weight_array[data.index]

			# create design matrix for regressions
			fmla = '{} ~ {}'.format(c, ' + '.join(predictors))
			endog, exog = dmatrices(fmla, data, return_type='dataframe')
			exog = sm.add_constant(exog)
			exog_index = [x for x in exog.index]
			weight_forWLS = weight_array.loc[pd.IndexSlice[exog_index]]
			weight_type = 'wtabc_allids_c' + cs + '_' + weight
			weight_forWLS = weight_forWLS.loc[:, weight_type]
			weight_forWLS.dropna(axis=0, inplace=True)
			
			exog = exog.loc[weight_forWLS.index,:]
			endog = endog.loc[weight_forWLS.index,:]
			# estimate coefficients
			fail_switch = 0
			try:
				model = sm.WLS(endog, exog, weights=weight_forWLS)
				fit = model.fit()
				params = fit.params
				resid = fit.resid
			except:
				fail_switch = 1
				if age in range(22, 30):
					params = pd.Series([np.nan for j in range(1 + len(predictors))], index=['Intercept'] + cols.interp.predictors + ['y'])
				else:
					params = pd.Series([np.nan for j in range(1 + len(predictors))], index=['Intercept'] + cols.extrap.predictors + ['y'])
				resid = pd.Series([np.nan for j in range(endog.shape[0])])
			
			# calculate RMSE
			rmse = resid * resid
			rmse =  pd.Series(sqrt(rmse.mean(axis=0)), index=['rmse'])
			params = pd.concat([params, rmse],axis=0)
			params.rename({'inc_labor{}'.format(age_x):'y'}, inplace=True)
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

	male_interp_nix = abcd.loc[abcd.male==1].loc[pd.isnull(abcd.loc[abcd.male==1, cols.interp.predictors]).any(axis=1)].index
	female_interp_nix = abcd.loc[abcd.male==0].loc[pd.isnull(abcd.loc[abcd.male==0, cols.interp.predictors]).any(axis=1)].index

	male_extrap_nix = abcd.loc[abcd.male==1].loc[pd.isnull(abcd.loc[abcd.male==1, cols.extrap.predictors]).any(axis=1)].index
	female_extrap_nix = abcd.loc[abcd.male==0].loc[pd.isnull(abcd.loc[abcd.male==0, cols.extrap.predictors]).any(axis=1)].index

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

		elif sex == 'male':
			abcd = abc.loc[abc.male==1]

		else:
			abcd = abc.loc[abc.male==0]

		abcd_interp = abcd.loc[:, ['Intercept'] + cols.interp.predictors + ['y']]
		abcd_extrap = abcd.loc[:, ['Intercept'] + cols.extrap.predictors + ['y']]
		
		projection_interp[sex] = pd.DataFrame([])
		projection_extrap[sex] = pd.DataFrame([])

		for age in ages: 
			if age in range(22, 30):
				if age == 22:
					abcd_interp['y'] = 0 
				params_interp_trans = pd.DataFrame(params_interp[sex].loc[age].drop('rmse').T)
				interp_dot = abcd_interp.dot(params_interp_trans) + error_mat[sex][[age]]
				abcd_interp['y'] = interp_dot
				projection_interp[sex] = pd.concat([projection_interp[sex], interp_dot], axis=1)	

			else:

				if age == 31:
					params_extrap[sex].loc[31]['y'] = 0
					abcd_extrap['y'] = interp_dot	
					abcd_extrap['y'].fillna(value=0, inplace=True)
				params_extrap_trans = pd.DataFrame(params_extrap[sex].loc[age].drop('rmse').T)
				extrap_dot = abcd_extrap.dot(params_extrap_trans) + error_mat[sex][[age]]
				abcd_extrap['y'] = extrap_dot
				projection_extrap[sex] =pd.concat([projection_extrap[sex],extrap_dot],axis=1)

			
	return params_interp, params_extrap, error_mat, projection_interp, projection_extrap


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
