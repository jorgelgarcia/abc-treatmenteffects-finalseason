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
2: ITT, with controls and IPW
3: P=0, "ITT" no controls
4: P=0, "ITT" with controls and IPW
5: P=0, matching
6: P=1, "ITT" no controls
7: P=1, "ITT" with controls and IPW
8: P=1, matching
'''
#----------------------------------------
# Generate the matrices of flows
#----------------------------------------
etype = 8
filled = makeflows(etype=etype)
benefits, costs = bcflows(filled=filled)
total = irrflows(filled=filled)

#----------------------------------------
# Estimate the IRR
#----------------------------------------

print 'Calculating IRR...'
irr_ages = {}
#for age in [5, 8, 15, 21, 30, 79]: 
for age in [79]:
    irr = total.loc[:, slice('c{}'.format(age))].apply(robust_irr, axis=1)
    point_f = irr.loc['f',0,0]
    point_m = irr.loc['m',0,0]
    point_p = irr.loc['p',0,0]

    qtrim = 0.05        
    q95 = irr.quantile(q=1-qtrim)
    q05 = irr.quantile(q=qtrim)
    
    irrf = irr.loc['f'].dropna()
    irrm = irr.loc['m'].dropna()
    irrp = irr.loc['p'].dropna()
    
    irrf = irrf.ix[(irrf>irrf.quantile(q=qtrim)) & (irrf<irrf.quantile(q=1-qtrim))]
    irrm = irrm.ix[(irrm>irrm.quantile(q=qtrim)) & (irrm<irrm.quantile(q=1-qtrim))]
    irrp = irrp.ix[(irrp>irrp.quantile(q=qtrim)) & (irrp<irrp.quantile(q=1-qtrim))]
    
    # Conduct inference    
    null_center = 0.03
    irr_fp = 1 - percentileofscore(irrf - irrf.mean() + null_center, point_f)/100
    irr_mp = 1 - percentileofscore(irrm - irrm.mean() + null_center, point_m)/100
    irr_pp = 1 - percentileofscore(irrp - irrp.mean() + null_center, point_p)/100

    # Save results
    irr_pnt = pd.DataFrame([point_f, point_m, point_p], index=['f','m','p'])    
    irr_mean = pd.DataFrame([irrf.mean(), irrm.mean(), irrp.mean()], index = ['f', 'm', 'p'])   
    irr_p = pd.DataFrame([irr_fp, irr_mp, irr_pp], index = ['f', 'm', 'p'])
    irr_se = pd.DataFrame([irrf.std(), irrm.std(), irrp.std()], index=['f','m','p'])    

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
        irr.to_csv(os.path.join(tables, 'all_irr_type{}.csv'.format(etype)), index=True)
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
#for age in [5, 8, 15, 21, 30, 79]:
for age in [79]:
    costs_age = costs.loc[:, slice('c{}'.format(age))].apply(robust_npv, axis=1)
    benefits_age = benefits.loc[:, slice('c{}'.format(age))].apply(robust_npv, axis=1)
    ratio = -benefits_age/costs_age


    point_f = ratio.loc['f',0,0]
    point_m = ratio.loc['m',0,0]
    point_p = ratio.loc['p',0,0]

    qtrim = 0.05        
    q95 = ratio.quantile(q=1-qtrim)
    q05 = ratio.quantile(q=qtrim)
    
    ratiof = ratio.loc['f'].dropna()
    ratiom = ratio.loc['m'].dropna()
    ratiop = ratio.loc['p'].dropna()

    ratiof = ratiof.ix[(ratiof>ratiof.quantile(q=qtrim)) & (ratiof<ratiof.quantile(q=1-qtrim))]
    ratiom = ratiom.ix[(ratiom>ratiom.quantile(q=qtrim)) & (ratiom<ratiom.quantile(q=1-qtrim))]
    ratiop = ratiop.ix[(ratiop>ratiop.quantile(q=qtrim)) & (ratiop<ratiop.quantile(q=1-qtrim))]
    
    # Conduct inference    
    null_center = 1  
    ratio_fp = 1 - percentileofscore(ratiof - ratiof.mean() + null_center, point_f)/100
    ratio_mp = 1 - percentileofscore(ratiom - ratiom.mean() + null_center, point_m)/100
    ratio_pp = 1 - percentileofscore(ratiop - ratiop.mean() + null_center, point_p)/100

    # MAKE ALL STATISTICS RELY ON THE QUANTILED VERSION

    # Save results
    ratio_pnt = pd.DataFrame([point_f, point_m, point_p], index=['f','m','p'])
    ratio_mean = pd.DataFrame([ratiof.mean(), ratiom.mean(), ratiop.mean()], index = ['f', 'm', 'p'])    
    ratio_p = pd.DataFrame([ratio_fp, ratio_mp, ratio_pp], index = ['f', 'm', 'p'])    
    ratio_se = pd.DataFrame([ratiof.std(), ratiom.std(), ratiop.std()], index=['f','m','p'])
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
        ratio.to_csv(os.path.join(tables, 'all_ratios_type{}.csv'.format(etype)), index=True)
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
