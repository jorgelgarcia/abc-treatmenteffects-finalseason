# -*- coding: utf-8 -*-
"""
Author      Joshua Shea
Date        July 5, 2016
Description This code uses the functions defined in cba_setup.py to estimate
            the IRR and BCR.
"""
import os
import pandas as pd
import numpy as np
from scipy.stats import percentileofscore
from cba_setup import *

'''
Select estimation type ('etype')
1: "ITT", no controls
2: ITT, with controls
3: P=0, "ITT" no controls
4: P=0, "ITT" with controls
5: P=0, matching
6: P=1, "ITT" no controls
7: P=1, "ITT" with controls
8: P=1, matching
'''
#----------------------------------------
# Generate the matrices of flows
#----------------------------------------
etype = 2
filled = makeflows(etype=etype)
benefits, costs = bcflows(filled=filled)
total = irrflows(filled=filled)

#----------------------------------------
# Estimate the IRR
#----------------------------------------

print 'Calculating IRR...'
irr_ages = {}
for age in [5, 8, 15, 21, 30, 79]: 
#for age in [30]:
    irr = total.loc[:, slice('c{}'.format(age))].apply(robust_irr, axis=1)

    # Conduct inference    
    null_center = 0  
    irr_fp = 1 - percentileofscore(irr.loc['f'].dropna() - irr.mean(level='sex').loc['f'] + null_center, irr.loc['f',0,0])/100
    irr_mp = 1 - percentileofscore(irr.loc['m'].dropna() - irr.mean(level='sex').loc['m'] + null_center, irr.loc['m',0,0])/100
    irr_pp = 1 - percentileofscore(irr.loc['p'].dropna() - irr.mean(level='sex').loc['p'] + null_center, irr.loc['p',0,0])/100

    # Save results
    irr_pnt = pd.DataFrame([irr.loc['f',0,0], irr.loc['m',0,0], irr.loc['p',0,0]], index=['f','m','p'])    
    irr_mean = irr.mean(level='sex')
    irr_p = pd.DataFrame([irr_fp, irr_mp, irr_pp], index = ['f', 'm', 'p'])
    irr_se = irr.std(level='sex')
    try:
        irr_quant = irr.groupby(level='sex').quantile([0.1, 0.9]).unstack()
    except:
        irr_quant = pd.DataFrame(np.array([[np.nan, np.nan], [np.nan, np.nan], [np.nan, np.nan]]), index = ['f', 'm', 'p'])
        irr_quant.index.name = 'sex'

    # Output the results
    table = pd.concat([irr_pnt, irr_mean, irr_p, irr_se, irr_quant], axis=1)
    table.columns = ['point', 'mean', 'pval', 'se', 'p10', 'p90']
    irr_ages[age] = table
    print 'Estimated IRR for ages 0--{}'.format(age)
    
    if age == 79:
        irr_pnt.to_csv(os.path.join(tables, 'irr_pnt.csv'), index=True, header=False)
        irr_p.to_csv(os.path.join(tables, 'irr_pval.csv'), index=True, header=False)
        irr.mean(level='sex').to_csv(os.path.join(tables, 'irr_mean.csv'),
                index=True)
        irr.groupby(level='sex').quantile([0.1, 0.9]).to_csv(os.path.join(tables, 'irr_ci.csv'),
                index=True)
        irr.std(level='sex').to_csv(os.path.join(tables, 'irr_se.csv'),
                index=True) 
    
irr_ages = pd.concat(irr_ages, axis=0, names=['age', 'sex'])
irr_ages.to_csv(os.path.join(tables, 'irr_age_type{}.csv'.format(etype)), index=True)

#----------------------------------------
# Estimate the benefit-cost ratios
#----------------------------------------

print 'Calculating B/C ratios...'
bcr_ages = {}
for age in [5, 8, 15, 21, 30, 79]:
#for age in [30]:
    costs_age = costs.loc[:, slice('c{}'.format(age))].apply(robust_npv, axis=1)
    benefits_age = benefits.loc[:, slice('c{}'.format(age))].apply(robust_npv, axis=1)
    ratio = -benefits_age/costs_age

    # Conduct inference
    null_center = 0
    ratio_fp = 1 - percentileofscore(ratio.loc['f'].dropna() - ratio.mean(level='sex').loc['f'] + null_center, ratio.loc['f',0,0])/100
    ratio_mp = 1 - percentileofscore(ratio.loc['m'].dropna() - ratio.mean(level='sex').loc['m'] + null_center, ratio.loc['m',0,0])/100
    ratio_pp = 1 - percentileofscore(ratio.loc['p'].dropna() - ratio.mean(level='sex').loc['p'] + null_center, ratio.loc['p',0,0])/100    
    
    # Save results
    ratio_pnt = pd.DataFrame([ratio.loc['f',0,0], ratio.loc['m',0,0], ratio.loc['p',0,0]], index=['f','m','p'])
    ratio_mean = ratio.mean(level='sex')
    ratio_p = pd.DataFrame([ratio_fp, ratio_mp, ratio_pp], index = ['f', 'm', 'p'])    
    ratio_se = ratio.std(level='sex')
    try:
        ratio_quant = ratio.groupby(level='sex').quantile([0.1, 0.9]).unstack()
    except:
        ratio_quant = pd.DataFrame(np.array([[np.nan, np.nan], [np.nan, np.nan], [np.nan, np.nan]]), index = ['f', 'm', 'p'])
        ratio_quant.index.name = 'sex'

    # Output results    
    table = pd.concat([ratio_pnt, ratio_mean, ratio_p, ratio_se, ratio_quant], axis=1)
    table.columns = ['point', 'mean', 'pval', 'se', 'p10', 'p90']
    bcr_ages[age] = table
    print 'Estimated B/C ratio for ages 0--{}'.format(age)

    if age == 79:    
        ratio_pnt.to_csv(os.path.join(tables, 'ratio_pnt.csv'), index=True, header=False)
        ratio_p.to_csv(os.path.join(tables, 'ratio_pval.csv'), index=True, header=False) 
        ratio.mean(level='sex').to_csv(os.path.join(tables, 'ratio_mean.csv'), 
        	index=True)
        ratio.groupby(level='sex').quantile([0.1, 0.9]).to_csv(os.path.join(tables, 'ratio_ci.csv'),
        	index=True)
        ratio.std(level='sex').to_csv(os.path.join(tables, 'ratio_se.csv'),
        	index=True)
    
bcr_ages = pd.concat(bcr_ages, axis=0, names=['age', 'sex'])
bcr_ages.to_csv(os.path.join(tables, 'ratios_age_type{}.csv'.format(etype)), index=True)
