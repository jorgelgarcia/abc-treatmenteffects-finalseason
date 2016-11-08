'''compute the rate of return'''
import os
from collections import OrderedDict
import pandas as pd
import numpy as np
from scipy.stats import percentileofscore
from cba_N import N
from math import sqrt
# Paths
filedir = os.path.join(os.path.dirname(__file__))
tables = os.path.join(filedir, 'rslt', 'tables')
if not os.path.exists(tables):
	os.mkdir(tables)

from cba_setup import robust_npv, makeflows, adraws, draws

etype = 8
filled = makeflows(etype=etype)

# aggregate certain componenets together
for sex in ['m', 'f', 'p']:
    filled['cc_{}'.format(sex)] = filled['ccpublic_{}'.format(sex)] + filled['ccprivate_{}'.format(sex)]
    filled['crime_{}'.format(sex)] = filled['crimepublic_{}'.format(sex)] + filled['crimeprivate_{}'.format(sex)]
    filled['health_{}'.format(sex)] = filled['health_public_{}'.format(sex)] + filled['health_private_{}'.format(sex)]
    filled['transfer_{}'.format(sex)] = filled['inc_trans_pub_{}'.format(sex)] + filled['diclaim_{}'.format(sex)] + filled['ssclaim_{}'.format(sex)] + filled['ssiclaim_{}'.format(sex)]

    filled['all_{}'.format(sex)] = filled['inc_labor_{}'.format(sex)] + filled['inc_parent_{}'.format(sex)] + filled['transfer_{}'.format(sex)] + filled['edu_{}'.format(sex)] + filled['crime_{}'.format(sex)] + filled['cc_{}'.format(sex)] + filled['health_{}'.format(sex)] + filled['qaly_{}'.format(sex)] + filled['costs_{}'.format(sex)] + filled['m_ed_{}'.format(sex)]

components = ['inc_labor', 'inc_parent', 'transfer', 'edu', 'crime', 'costs', 'cc', 'health', 'qaly',
              'health_public', 'health_private', 'inc_trans_pub','diclaim', 'ssclaim', 'ssiclaim', 'm_ed', 'all', 'crimepublic'] #

output = pd.DataFrame([])
for part in components:
	tmp = pd.DataFrame(0.,
		index=pd.MultiIndex.from_product([['m', 'f', 'p'], [i for i in range(adraws)], [j for j in range(draws)]], names=['sex', 'adraw', 'draw']),
		columns=['c{}'.format(i) for i in xrange(80)])
	tmp.sort_index(inplace=True)

	for sex in ['m', 'f', 'p']:
		tmp.loc[(sex, slice(None), slice(None)), :] = filled['{}_{}'.format(part, sex)]

	npv = tmp.apply(robust_npv, rate=0, axis=1)

        npvf = npv.loc['f'].dropna()
        npvm = npv.loc['m'].dropna()
        npvp = npv.loc['p'].dropna()

 	point = pd.DataFrame(npv.loc[slice(None), 0,0])
 	point.columns = ['value']
 	point['part'] = part
 	point['type'] = 'point'
 	point.set_index(['part', 'type'], append=True, inplace=True)

        qtrim = 0.05

        npvf = npvf.ix[(npvf>npvf.quantile(q=qtrim)) & (npvf<npvf.quantile(q=1-qtrim))]
        npvm = npvm.ix[(npvm>npvm.quantile(q=qtrim)) & (npvm<npvm.quantile(q=1-qtrim))]
        npvp = npvp.ix[(npvp>npvp.quantile(q=qtrim)) & (npvp<npvp.quantile(q=1-qtrim))]

 	#npv_fp = 1 - percentileofscore(npv.loc['f'].dropna() - npv.mean(level='sex').loc['f'], npv.loc['f',0,0])/100
    	#npv_mp = 1 - percentileofscore(npv.loc['m'].dropna() - npv.mean(level='sex').loc['m'], npv.loc['m',0,0])/100
    	#npv_pp = 1 - percentileofscore(npv.loc['p'].dropna() - npv.mean(level='sex').loc['p'], npv.loc['p',0,0])/100

        npv_fp = 1 - percentileofscore(npvf - npvf.mean(), npvf.mean())/100
    	npv_mp = 1 - percentileofscore(npvm - npvm.mean(), npvm.mean())/100
    	npv_pp = 1 - percentileofscore(npvp - npvp.mean(), npvp.mean())/100
        
    	npv_p = pd.DataFrame([npv_fp, npv_mp, npv_pp], index = ['f', 'm', 'p'], columns=['value'])
    	npv_p['part']=part
    	npv_p['type']='pval'
    	npv_p.set_index(['part', 'type'], append=True, inplace=True)

 	#mean = pd.DataFrame(npv.mean(level='sex'))
 	#mean.columns = ['value']
	
        mean = pd.DataFrame([npvf.mean(), npvm.mean(), npvp.mean()], index = ['f', 'm', 'p'], columns=['value'])
        mean['part']=part
	mean['type']='mean'
	mean.set_index(['part', 'type'], append=True, inplace=True)

 	#se = pd.DataFrame(npv.std(level='sex'))
        #se.columns = ['value']

        se = pd.DataFrame([npvf.std(), npvm.std(),npvp.std()], index = ['f', 'm', 'p'], columns=['value'])
 	se['part']=part
 	se['type']='se'
 	se.set_index(['part', 'type'], append=True, inplace=True)

 	quantile = pd.DataFrame(npv.groupby(level='sex').quantile([0.1, 0.9]))
 	quantile.columns = ['value']
 	quantile.index.names=['sex', 'type']
 	quantile['part']=part
 	quantile.set_index(['part'], append=True, inplace=True)
  	quantile = quantile.reorder_levels(['sex','part','type'])

  	output = output.append([point, mean, se, npv_p, quantile])

  	print 'Completed NPV calculation for {}...'.format(part)

output.sort_index(inplace=True)
output.to_csv(os.path.join(tables, 'npv_type{}_ped.csv'.format(etype)), index=True)
npv.to_csv(os.path.join(tables, 'all_npvs_type{}_ped.csv'.format(etype)), index=True)
