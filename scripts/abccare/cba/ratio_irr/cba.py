# -*- coding: utf-8 -*-
"""
Author      Joshua Shea
Date        July 5, 2016
Description This code uses the functions defined in cba_setup.py to estimate
            the IRR and BCR.
            
WARNING     THE QUANTILES IN THE bc_calc AND irr_calc FUNCTIONS HAVE NOT BEEN UPDATED FOR TRIMMING            
"""
import os
import pandas as pd
import numpy as np
from scipy.stats import percentileofscore, zscore
from cba_setup import *
from math import sqrt
from cba_N import N
'''
Select estimation type ('etype')
1: "ITT", no controls
2: ITT, with controls and IPW
3: P=0, "ITT" no controls
4: P=0, "ITT" with controls and IPWc
5: P=0, matching
6: P=1, "ITT" no controls
7: P=1, "ITT" with controls and IPW
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

# this alternate version saves all the roots
# find a better way to do this.

def robust_irr_roots(values):
    try:
        res = np.roots(values[::-1])
        mask = (res.imag == 0) & (res.real > 0)
        if res.size == 0:
            return np.nan
        res = res[mask].real
        rate = 1.0/res - 1
        global roots
        roots = roots + [rate]
   
        # NPV(rate) = 0 can have more than one solution so we return
        # only the solution closest to zero.
        lim_rate = [r for r in list(rate) if (r<1)]     
        lim_rate = lim_rate[np.argmin(np.abs(lim_rate))]
        return lim_rate
        
    except:
        return np.nan  

#----------------------------------------
# Estimate the IRR
#----------------------------------------

print 'Calculating IRR...'
irr_ages = {}
for age in [5, 8, 15, 21, 30, 79]: 
#for age in [79]:
    if age == 79:
        roots = []
        irr = total.loc[:, slice('c{}'.format(age))].apply(robust_irr_roots, axis=1) 

    else:
        irr = total.loc[:, slice('c{}'.format(age))].apply(robust_irr, axis=1)
    point_f = irr.loc['f',0,0]
    point_m = irr.loc['m',0,0]
    point_p = irr.loc['p',0,0]

    qtrim = 0
    
    irrf = irr.loc['f'].dropna()
    irrm = irr.loc['m'].dropna()
    irrp = irr.loc['p'].dropna()
    
    #irrf = irrf.ix[(irrf>irrf.quantile(q=qtrim)) & (irrf<irrf.quantile(q=1-qtrim))]
    #irrm = irrm.ix[(irrm>irrm.quantile(q=qtrim)) & (irrm<irrm.quantile(q=1-qtrim))]
    #irrp = irrp.ix[(irrp>irrp.quantile(q=qtrim)) & (irrp<irrp.quantile(q=1-qtrim))]

    irrf = irrf.ix[irrf > 0]
    irrm = irrm.ix[irrm > 0]
    irrp = irrp.ix[irrp > 0]
    
    # Conduct inference    
    null_center = 0.03
    #irr_fp = 1 - percentileofscore(irrf - irrf.mean() + null_center, point_f)/100
    #irr_mp = 1 - percentileofscore(irrm - irrm.mean() + null_center, point_m)/100
    #irr_pp = 1 - percentileofscore(irrp - irrp.mean() + null_center, point_p)/100

    irr_fp = 1 - percentileofscore(irrf - irrf.mean() + null_center, irrf.mean())/100
    irr_mp = 1 - percentileofscore(irrm - irrm.mean() + null_center, irrm.mean())/100
    irr_pp = 1 - percentileofscore(irrp - irrp.mean() + null_center, irrp.mean())/100

    # Save results
    irr_pnt = pd.DataFrame([point_f, point_m, point_p], index=['f','m','p'])    
    irr_mean = pd.DataFrame([irrf.mean(), irrm.mean(), irrp.mean()], index = ['f', 'm', 'p'])   
    irr_p = pd.DataFrame([irr_fp, irr_mp, irr_pp], index = ['f', 'm', 'p'])
    irr_se = pd.DataFrame([np.std(irrf)/sqrt(N['f'][etype]),np.std(irrm)/sqrt(N['m'][etype]), np.std(irrp)/sqrt(N['p'][etype])], index=['f','m','p'])    

    try:
        #irr_quant = irr.groupby(level='sex').quantile([0.1, 0.9]).unstack()
        irr_quant = pd.DataFrame(np.array([[irrf.quantile(0.10),irrf.quantile(0.90)],[irrm.quantile(0.10),irrm.quantile(0.90)],[irrp.quantile(0.10),irrp.quantile(0.90)]]), index=['f','m','p'])
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
        irr_mean.to_csv(os.path.join(tables, 'irr_mean.csv'), index=True, header=False)
        irr.groupby(level='sex').quantile([0.1, 0.9]).to_csv(os.path.join(tables, 'irr_ci.csv'),
                index=True)
        irr_se.to_csv(os.path.join(tables, 'irr_se.csv'), index=True, header=False) 
        roots = pd.DataFrame(roots) #, index=irr.index
        roots.to_csv(os.path.join(tables, 'all_roots_type{}.csv'.format(etype)), index=False)
    
irr_ages = pd.concat(irr_ages, axis=0, names=['age', 'sex'])
irr_ages.to_csv(os.path.join(sensitivity, 'irr_age_type{}.csv'.format(etype)), index=True)

#----------------------------------------
# Estimate the benefit-cost ratios
#----------------------------------------

print 'Calculating B/C ratios...'
bcr_ages = {}
for age in [5, 8, 15, 21, 30, 79]:
#for age in [79]:
    costs_age = costs.loc[:, slice('c{}'.format(age))].apply(robust_npv, axis=1)
    benefits_age = benefits.loc[:, slice('c{}'.format(age))].apply(robust_npv, axis=1)
    ratio = -benefits_age/costs_age
    
    point_f = ratio.loc['f',0,0]
    point_m = ratio.loc['m',0,0]
    point_p = ratio.loc['p',0,0]

    qtrim = 0.05
   
    ratiof = ratio.loc['f'].dropna()
    ratiom = ratio.loc['m'].dropna()
    ratiop = ratio.loc['p'].dropna()

    ratiof = ratiof.ix[(ratiof>ratiof.quantile(q=qtrim)) & (ratiof<ratiof.quantile(q=1-qtrim))]
    ratiom = ratiom.ix[(ratiom>ratiom.quantile(q=qtrim)) & (ratiom<ratiom.quantile(q=1-qtrim))]
    ratiop = ratiop.ix[(ratiop>ratiop.quantile(q=qtrim)) & (ratiop<ratiop.quantile(q=1-qtrim))]
    
    # Conduct inference    
    null_center = 1  

    ratio_fp = 1 - percentileofscore(ratiof - ratiof.mean() + null_center, ratiof.mean())/100
    ratio_mp = 1 - percentileofscore(ratiom - ratiom.mean() + null_center, ratiom.mean())/100
    ratio_pp = 1 - percentileofscore(ratiop - ratiop.mean() + null_center, ratiop.mean())/100

    # Save results
    ratio_pnt = pd.DataFrame([point_f, point_m, point_p], index=['f','m','p'])
    ratio_mean = pd.DataFrame([ratiof.mean(), ratiom.mean(), ratiop.mean()], index = ['f', 'm', 'p'])    
    ratio_p = pd.DataFrame([ratio_fp, ratio_mp, ratio_pp], index = ['f', 'm', 'p'])    
    ratio_se = pd.DataFrame([np.std(ratiof)/sqrt(N['f'][etype]),np.std(ratiom)/sqrt(N['m'][etype]), np.std(ratiop)/sqrt(N['p'][etype])], index=['f','m','p'])
    
    try:
        #ratio_quant = ratio.groupby(level='sex').quantile([0.1, 0.9]).unstack()
        ratio_quant = pd.DataFrame(np.array([[ratiof.quantile(0.10),ratiof.quantile(0.90)],[ratiom.quantile(0.10),ratiom.quantile(0.90)],[ratiop.quantile(0.10),ratiop.quantile(0.90)]]), index=['f','m','p'])
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
        ratio_mean.to_csv(os.path.join(tables,'ratio_mean.csv'), index=True, header=False)
        ratio_se.to_csv(os.path.join(tables,'ratio_se.csv'), index=True,header=False)
        ratio.groupby(level='sex').quantile([0.1, 0.9]).to_csv(os.path.join(tables, 'ratio_ci.csv'),
                index=True)
    
bcr_ages = pd.concat(bcr_ages, axis=0, names=['age', 'sex'])
bcr_ages.to_csv(os.path.join(sensitivity, 'ratios_age_type{}.csv'.format(etype)), index=True)
