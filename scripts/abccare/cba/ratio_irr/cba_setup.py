# -*- coding: utf-8 -*-
"""
Author      Joshua Shea
Date        July 5, 2016
Description This code defines all the functions used to estimate the IRR and BCR.
            This includes functions to estimate the NPV and IRR.   
            
WARNING     THE QUANTILES IN THE bc_calc AND irr_calc FUNCTIONS HAVE NOT BEEN UPDATED FOR TRIMMING
"""
import os
from collections import OrderedDict
import pandas as pd
import numpy as np
from scipy.stats import percentileofscore, zscore
from math import sqrt
from cba_N import N

'''+
1: "ITT", no controls
2: ITT, with controls and weights
3: P=0, "ITT" no controls
4: P=0, "ITT" with controls  and weights
5: P=0, matching
6: P=1, "ITT" no controls
7: P=1, "ITT" with controls  and weights
8: P=1, matching
9: ITT, with controls
10: P=0, with controls
11: P=1, with controls
'''
#----------------------------------------

# Bootstrap samples
draws = 100
adraws = 100

# Paths
filedir = os.path.join(os.path.dirname(__file__))
tables = os.path.join(filedir, 'rslt', 'tables')
sensitivity = os.path.join(filedir, 'rslt', 'sensitivity')

#----------------------------------------

# Result files
flows = {
    # Income and Education
    'inc_labor':{'m':'labor_m.csv', 'f':'labor_f.csv', 'p':'labor_p.csv'},
    'inc_parent':{'m':'ip_p_inc_m.csv', 'f':'ip_p_inc_f.csv', 'p':'ip_p_inc_p.csv'},
    #'inc_parent_ext':{'m':'p_inc_m.csv', 'f':'p_inc_f.csv', 'p':'p_inc_p.csv'},
    'inc_trans_pub':{'m':'transfer_m.csv', 'f':'transfer_f.csv', 'p':'transfer_p.csv'},
    'edu':{'m':'educost_m.csv', 'f':'educost_f.csv', 'p':'educost_p.csv'},
	'm_ed':{'m':'m_educost_m.csv', 'f':'m_educost_f.csv', 'p':'m_educost_p.csv'},
    # Crime
    'crimepublic':{'m':'public_crime_m.csv', 'f':'public_crime_f.csv', 'p':'public_crime_p.csv'},
    'crimeprivate':{'m':'private_crime_m.csv', 'f':'private_crime_f.csv', 'p':'private_crime_p.csv'},
    # Program Costs
    'costs':{'m':'progcost_p.csv', 'f':'progcost_p.csv', 'p':'progcost_p.csv'},
    # Control Prek Services
    'ccpublic':{'m':'cccostpublic_m.csv', 'f':'cccostpublic_f.csv', 'p':'cccostpublic_p.csv'},
    'ccprivate':{'m':'cccostprivate_m.csv', 'f':'cccostprivate_f.csv', 'p':'cccostprivate_p.csv'},
    # Health
    'health_private': {'m': 'health_private_m.csv', 'f':'health_private_f.csv', 'p':'health_private_p.csv'},
    'health_public': {'m': 'health_public_m.csv', 'f':'health_public_f.csv', 'p':'health_public_p.csv'},
    'qaly': {'m': 'qaly_m.csv', 'f':'qaly_f.csv', 'p':'qaly_p.csv'},
    # Transfer claims
    'diclaim':{'m': 'diclaim_m.csv', 'f':'diclaim_f.csv', 'p':'diclaim_p.csv' },
    'ssiclaim':{'m': 'ssiclaim_m.csv', 'f':'ssiclaim_f.csv', 'p':'ssiclaim_p.csv' },
    'ssclaim':{'m': 'ssclaim_m.csv', 'f':'ssclaim_f.csv', 'p':'ssclaim_p.csv' }
}

#----------------------------------------

# declare function to prepare matrices of flows
def makeflows(etype):
    edict = {}
    edict[1] = os.path.join(filedir, 'flows', 'ncc_noctrl')
    edict[2] = os.path.join(filedir, 'flows', 'ncc_wctrl')
    edict[3] = os.path.join(filedir, 'flows', 'p0_noctrl')
    edict[4] = os.path.join(filedir, 'flows', 'p0_ctrl')
    edict[5] = os.path.join(filedir, 'flows', 'p0_match')
    edict[6] = os.path.join(filedir, 'flows', 'p1_noctrl')
    edict[7] = os.path.join(filedir, 'flows', 'p1_ctrl')
    edict[8] = os.path.join(filedir, 'flows', 'p1_match')
    edict[9] = os.path.join(filedir, 'flows', 'ncc_ctrl')
    edict[10] = os.path.join(filedir, 'flows', 'p0_ctrl')
    edict[11] = os.path.join(filedir, 'flows', 'p1_ctrl')
    flowscsv = edict[etype]
     
    # DI claim file
    diclaim_tmp = pd.read_csv(os.path.join(filedir, 'diclaim', 'di_claim.csv'), names='age')
    diclaim_tmp = diclaim_tmp.T
    diclaim_tmp.columns = ['sex'] + ['c{}'.format(i) for i in xrange(20,66)]
    diclaim_tmp.set_index('sex', inplace=True)
    
    diclaim = pd.DataFrame(0., index=pd.Index(['p', 'm', 'f'], name='sex'), 
    	columns=['c{}'.format(i) for i in xrange(109)])
    
    diclaim.loc[diclaim_tmp.index, diclaim_tmp.columns] = diclaim_tmp

    diclaim.to_csv(os.path.join(tables,'diclaim_test.csv'), index=True)

    filled = OrderedDict()

    for sex in ['m', 'f', 'p']:
        #Filling with zero entries, and stacking non-auxiliary bootstrap estiamtes
        for key, file_ in flows.items():
            if key in ['costs', 'ccpublic', 'ccprivate', 'edu', 'm_ed', 'inc_parent', 'crimepublic', 'crimeprivate']:
                df = pd.read_csv(os.path.join(flowscsv, file_[sex]), index_col=['draw'])
                tmp_full = df

                full = pd.DataFrame([])
                for adraw in range(adraws):
                    tmp_full['adraw'] = adraw
                    full = pd.concat([full, df], axis=0)
    
                full['sex'] = sex
                full = full.set_index(['sex', 'adraw'], append=True)
                full = full.reorder_levels(['sex', 'adraw', 'draw'], axis=0).sort_index()
                full.fillna(0, inplace=True)       
                filled.update({'{}_{}'.format(key, sex):full})
                print 'Prepared {} for sex {}...'.format(key, sex)
            
            if key in ['health_private', 'health_public', 'inc_labor', 'inc_trans_pub', 'qaly', 'diclaim', 'ssclaim', 'ssiclaim']: 
                df = pd.read_csv(os.path.join(flowscsv, file_[sex]), index_col=['adraw','draw'])
                full = pd.DataFrame(0., index=pd.MultiIndex.from_product([range(adraws), range(draws)], names=['adraw','draw']), 
                                    columns=['c{}'.format(i) for i in xrange(109)])
		
                full.loc[full.index, full.columns] = df.loc[full.index, full.columns]
                full['sex'] = sex
                full = full.set_index('sex', append=True)   
                full = full.reorder_levels(['sex', 'adraw', 'draw'], axis=0).sort_index()   
                full.fillna(0, inplace=True)          
                if key == "diclaim":
                    full = full.astype(float) * diclaim.astype(float)
                filled.update({'{}_{}'.format(key, sex):full})
                print 'Prepared {} for sex {}...'.format(key, sex)

        # Cost adjustments, including DWL
        filled['inc_trans_pub_{}'.format(sex)] = -0.5*filled['inc_trans_pub_{}'.format(sex)]
        filled['costs_{}'.format(sex)] = -1.5*filled['costs_{}'.format(sex)]
        filled['edu_{}'.format(sex)] = -filled['edu_{}'.format(sex)]
        filled['edu_{}'.format(sex)].iloc[:, :19] = 1.5*filled['edu_{}'.format(sex)].iloc[:, :19]
	filled['m_ed_{}'.format(sex)] = -filled['m_ed_{}'.format(sex)]
        filled['m_ed_{}'.format(sex)].iloc[:, :19] = 1.5*filled['m_ed_{}'.format(sex)].iloc[:, :19]
        filled['crimepublic_{}'.format(sex)] = -1.5*filled['crimepublic_{}'.format(sex)]
        filled['crimeprivate_{}'.format(sex)] = -filled['crimeprivate_{}'.format(sex)]
        filled['ccpublic_{}'.format(sex)] = -1.5*filled['ccpublic_{}'.format(sex)]
        filled['ccprivate_{}'.format(sex)] = -filled['ccprivate_{}'.format(sex)]
        filled['health_private_{}'.format(sex)] = -filled['health_private_{}'.format(sex)] * 1.1 
        filled['health_public_{}'.format(sex)] = -1.5*filled['health_public_{}'.format(sex)] * 1.1
        filled['qaly_{}'.format(sex)] = 150000*filled['qaly_{}'.format(sex)]
        filled['diclaim_{}'.format(sex)] = -0.5*filled['diclaim_{}'.format(sex)]
        filled['ssiclaim_{}'.format(sex)] = -0.5*filled['ssiclaim_{}'.format(sex)] * 1.02 * 12 * 901.5 # averaged beween single and married
        filled['ssclaim_{}'.format(sex)] = -0.5*filled['ssclaim_{}'.format(sex)]  * 1.02 * 12 * 1228 # averaged between retired, widowed, disabled
        
    print "Prepared general matrix of all flows"
    return filled

#----------------------------------------

def robust_irr(values):
    try:
        res = np.roots(values[::-1])
        mask = (res.imag == 0) & (res.real > 0)
        if res.size == 0:
            return np.nan
        res = res[mask].real
        rate = 1.0/res - 1
  
        # NPV(rate) = 0 can have more than one solution so we return
        # only the solution closest to zero.
        lim_rate = [r for r in list(rate) if (r<1)]     
        lim_rate = lim_rate[np.argmin(np.abs(lim_rate))]
        return lim_rate
        
    except:
        return np.nan  

#----------------------------------------

def robust_npv(values, rate=0.03):
	try:
		return np.npv(rate, values)
	except:
		return np.nan

#----------------------------------------

def bcflows(filled, components=flows.keys()):
    benefits= pd.DataFrame(0., 
                           index=pd.MultiIndex.from_product([['m', 'f', 'p'], [i for i in range(adraws)], [j for j in range(draws)]], names=['sex', 'adraw', 'draw']), \
                           columns=['c{}'.format(i) for i in xrange(109)])
    benefits.sort_index(inplace=True)
    costs= pd.DataFrame(0., 
                        index=pd.MultiIndex.from_product([['m', 'f', 'p'], [i for i in range(adraws)], [j for j in range(draws)]], names=['sex', 'adraw', 'draw']), \
                        columns=['c{}'.format(i) for i in xrange(109)])
    costs.sort_index(inplace=True)

    for sex in ['m','f','p']:
        # Benefits, for B/C ratio
        for key in [c for c in components if c!= 'costs']:
            benefits.loc[(sex, slice(None), slice(None)), :] = benefits.loc[(sex, slice(None), slice(None)), :] + filled['{}_{}'.format(key, sex)]

            print 'Summed {} for sex {} in benefits dataframe...'.format(key, sex)
        # Costs, for B/C ratio        
        for key in ['costs']:
            costs.loc[(sex, slice(None), slice(None)), :] = costs.loc[(sex, slice(None), slice(None)), :] + filled['{}_{}'.format(key, sex)]
            print 'Formed costs dataframe for sex...'.format(key, sex)
    
    return benefits, costs

#----------------------------------------

def irrflows(filled, components=flows.keys()):
    total = pd.DataFrame(0., 
                         index=pd.MultiIndex.from_product([['m', 'f', 'p'], [i for i in range(adraws)], [j for j in range(draws)]], names=['sex', 'adraw', 'draw']), \
                         columns=['c{}'.format(i) for i in xrange(109)])
    total.sort_index(inplace=True)

    for sex in ['m', 'f', 'p']:
        # Total, for IRR
        for key in components:
            total.loc[(sex, slice(None), slice(None)), :] = total.loc[(sex, slice(None), slice(None)), :] + filled['{}_{}'.format(key, sex)]
            #print 'Summed {} for sex {} in IRR dataframe...'.format(key, sex)

        print '\nCompleted IRR data frame for sex {}.\n'.format(sex)
        
    return total

#----------------------------------------

def bc_calc(filled, etype, components=flows.keys(), rate=0.03):

    # prepare matrix of flows
    benefits, costs = bcflows(filled, components = components)

    # Cost-benefit Ratio
    print 'Calculating B/C ratio...'
    costs = costs.apply(robust_npv, rate=rate, axis=1)
    benefits = benefits.apply(robust_npv, rate=rate, axis=1)
    ratio = -benefits/costs
   
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
    ratio_se = pd.DataFrame([ratiof.std(),ratiom.std(), ratiop.std()], index=['f','m','p'])

    try:
        #ratio_quant = ratio.groupby(level='sex').quantile([0.1, 0.9]).unstack()
        ratio_quant = pd.DataFrame(np.array([[ratiof.quantile(0.10),ratiof.quantile(0.90)],[ratiom.quantile(0.10),ratiom.quantile(0.90)],[ratiop.quantile(0.10),ratiop.quantile(0.90)]]), index=['f','m','p'])
    except:
        ratio_quant = pd.DataFrame(np.array([[np.nan, np.nan], [np.nan, np.nan], [np.nan, np.nan]]), index = ['f', 'm', 'p'])
        ratio_quant.index.name = 'sex'

    # Output results    
    table = pd.concat([ratio_pnt, ratio_mean, ratio_p, ratio_se, ratio_quant], axis=1)
    table.columns = ['point', 'mean', 'pval', 'se', 'lb', 'ub']
    return table

#----------------------------------------

def irr_calc(filled, etype, components=flows.keys()):        	

    # prepare matrix of flows 
    total = irrflows(filled, components=components)

    # Rate of Return
    print 'Calculating IRR...'
    irr = total.apply(robust_irr, axis=1)
    
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
    irr_fp = 1 - percentileofscore(irrf - irrf.mean() + null_center, irrf.mean())/100
    irr_mp = 1 - percentileofscore(irrm - irrm.mean() + null_center, irrm.mean())/100
    irr_pp = 1 - percentileofscore(irrp - irrp.mean() + null_center, irrp.mean())/100

    # Save results
    irr_pnt = pd.DataFrame([point_f, point_m, point_p], index=['f','m','p'])    
    irr_mean = pd.DataFrame([irrf.mean(), irrm.mean(), irrp.mean()], index = ['f', 'm', 'p'])   
    irr_p = pd.DataFrame([irr_fp, irr_mp, irr_pp], index = ['f', 'm', 'p'])
    irr_se = pd.DataFrame([irrf.std(),irrm.std(), irrp.std()], index=['f','m','p'])    

    try:
        #irr_quant = irr.groupby(level='sex').quantile([0.1, 0.9]).unstack()
        irr_quant = pd.DataFrame(np.array([[irrf.quantile(0.10),irrf.quantile(0.90)],[irrm.quantile(0.10),irrm.quantile(0.90)],[irrp.quantile(0.10),irrp.quantile(0.90)]]), index=['f','m','p'])
    except:
        irr_quant = pd.DataFrame(np.array([[np.nan, np.nan], [np.nan, np.nan], [np.nan, np.nan]]), index = ['f', 'm', 'p'])
        irr_quant.index.name = 'sex'

    # Output the results
    table = pd.concat([irr_pnt, irr_mean, irr_p, irr_se, irr_quant], axis=1)
    table.columns = ['point', 'mean', 'pval', 'se', 'lb', 'ub']

    return table
     
