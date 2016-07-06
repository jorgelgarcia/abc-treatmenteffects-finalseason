# -*- coding: utf-8 -*-
"""
Created on Fri Apr  8 14:29:00 2016

@author: jkcshea

Desc:   This code selects the IPW variables for specific ABC outcomes.
        We only do this for the pooled sample to increase power. We use
        a linear probiaility model for this. We select the 3 variables
        that minimize the BIC.
"""
import pandas as pd
from pandas.io.stata import StataReader
import numpy as np
import statsmodels.api as sm
from patsy import dmatrices
import itertools
from paths import paths

# import data
reader = StataReader(paths.abccare)
data = reader.data(convert_dates=False, convert_categoricals=False)
data = data.set_index('id')
data = data.sort_index()
data.drop(data.loc[(data.RV==1) & (data.R==0)].index, inplace=True)

# bring in outcomes files, and find the ABC-only/CARE-only ones
outcomes = pd.read_csv(paths.outcomes, index_col='variable')
only_abc = outcomes.loc[outcomes.only_abc == 1].index
only_care = outcomes.loc[outcomes.only_care == 1].index

bank = pd.read_csv(paths.controls)
ipwvars = np.unique(outcomes.loc[~outcomes.ipw_var.isnull(),'ipw_var'].get_values())

# generate the list of all possible models
models = itertools.chain.from_iterable([itertools.combinations(bank.loc[:, 'variable'], 3)])
models = list(models)

# perform model selection
for var in ipwvars:
    if var in only_abc: 
        data_mod = data.loc[data.abc==1,:]
    elif var in only_care:
        data_mod = data.loc[data.abc==0,:]
    else:
        data_mod = data
    
    data_mod.loc[:, 'att_var'] = 1 - data_mod.loc[:,var].isnull().astype(int)

    minaic = np.inf
    minbic = np.inf
    best_model_aic = []
    best_model_bic = []
    best_model_aic_index = -1
    best_model_bic_index = -1
    best_model_aic_N = 0
    best_model_bic_N = 0
    i = 0

    for m in models:
        i += 1

        fmla = 'att_var ~ {}'.format(' + '.join(m)) 
        print "Variable {}, Iteration {}...".format(var, i)
        # try and estimate linear probability model
        try:
            obs, exog = dmatrices(fmla, data_mod, return_type='dataframe')
            
            model = sm.OLS(obs, exog)
            fit = None
            fit = model.fit()
    
            model_aic = fit.aic
            model_bic = fit.bic
    
            if model_aic <= minaic:
                minaic = model_aic
                best_model_aic = m
                best_model_aic_index = i
                best_model_aic_N = obs.shape[0]
                
            if model_bic <= minbic:
                minbic = model_bic
                best_model_bic = m
                best_model_bic_index = i
                best_model_bic_N = obs.shape[0]
                
        except:
            pass

    for i, ivar in enumerate(best_model_bic):        
        outcomes.loc[outcomes.ipw_var == var, 'ipw_pooled{}'.format(i + 1)] = ivar
    data_mod.drop('att_var', axis=1, inplace=True)
    
# update outcomes.csv with the IPW vars
outcomes.to_csv(paths.outcomes, index=True)


