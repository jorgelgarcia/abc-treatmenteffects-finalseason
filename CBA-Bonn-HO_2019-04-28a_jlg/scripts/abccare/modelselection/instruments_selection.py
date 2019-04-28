# -*- coding: utf-8 -*-
"""
Created on Mon Mar 28 21:05:37 2016

@author: jkcshea

Desctiption: this code estimates the linear probability model used to predict 
enrollment into alternative care. We use a model selection approach to do this.
The 3 variables with the lowest BIC are chosen.
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
data.drop(data.loc[(data.R==1)].index, inplace=True)
data.drop(data.loc[(data.RV==1)].index, inplace=True)

bank = pd.read_csv(paths.instruments)
models = itertools.chain.from_iterable([itertools.combinations(bank.loc[:, 'variable'], 3)])

minaic = np.inf
minbic = np.inf
best_model_aic = []
best_model_bic = []
best_model_aic_index = -1
best_model_bic_index = -1
best_model_aic_N = 0
best_model_bic_N = 0

for i,m in enumerate(models):
    fmla = 'P ~ male + abc + {}'.format(' + '.join(m)) 
    # try and estimate linear probability model
    try:
        preschool, exog = dmatrices(fmla, data, return_type='dataframe')
        
        model = sm.OLS(preschool, exog)
        fit = None
        fit = model.fit()

        model_aic = fit.aic
        model_bic = fit.bic

        if model_aic <= minaic:
            minaic = model_aic
            best_model_aic = m
            best_model_aic_index = i
            best_model_aic_N = preschool.shape[0]
        if model_bic <= minbic:
            minbic = model_bic
            best_model_bic = m
            best_model_bic_index = i
            best_model_bic_N = preschool.shape[0]
        
    except:
        pass

fmla_aic = 'P ~ {}'.format(' + '.join(best_model_aic)) 
fmla_bic = 'P ~ {}'.format(' + '.join(best_model_bic))

print "AIC model:", best_model_aic_index, fmla_aic
print "BIC model:", best_model_bic_index, fmla_bic

record = open('best_instruments.txt', 'wb')    
record.write('Best AIC: male {} \n\n'.format(' '.join(best_model_aic)))
record.write('Best BIC: male {} \n\n'.format(' '.join(best_model_bic)))
record.close()

