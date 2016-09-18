'''compute the rate of return'''
import os
import sys

from joblib import Parallel, delayed
import itertools
import pandas as pd
import numpy as np
from copy import deepcopy

# Paths
sys.path.extend([os.path.join(os.path.dirname(__file__), '..')])
filedir = os.path.join(os.path.dirname(__file__))
plots = os.path.join(filedir, '..', 'rslt', 'sensitivity')
from cba_N import N
from cba_setup import bc_calc, makeflows

etype = 2
filled = makeflows(etype=etype)

for sex in ['m', 'f', 'p']:
    filled['cc_{}'.format(sex)] = filled['ccpublic_{}'.format(sex)] + filled['ccprivate_{}'.format(sex)]    
    filled['crime_{}'.format(sex)] = filled['crimepublic_{}'.format(sex)] + filled['crimeprivate_{}'.format(sex)]
    filled['health_{}'.format(sex)] = filled['health_private_{}'.format(sex)] + filled['health_public_{}'.format(sex)] 
    filled['transfer_{}'.format(sex)] = filled['inc_trans_pub_{}'.format(sex)] + filled['diclaim_{}'.format(sex)] + filled['ssclaim_{}'.format(sex)] + filled['ssiclaim_{}'.format(sex)]

components = ['inc_labor', 'inc_parent', 'transfer', 'edu', 'crime', 'costs', 'cc', 'health', 'qaly', 'm_ed']
factors = np.arange(0,3.1,0.25)

combo = list(itertools.product(components, factors))
    
# vary factor: BCR
# applying factor to benefits        

def bc_factors(part, f):    
    bc_tmp = deepcopy(filled)
    for sex in ['m', 'f', 'p']:
        bc_tmp['{}_{}'.format(part, sex)] = bc_tmp['{}_{}'.format(part, sex)] * f

    output = bc_calc(bc_tmp, etype=etype, components=components)        

    output['rate'] = f
    output['part'] = part

    print 'B/C Ratio for {} and factor {} calculated.'.format(part, f)
    return output



bc_factors = Parallel(n_jobs=25)(
	delayed(bc_factors)(part, f) for part, f in combo)
bc_factors = pd.concat(bc_factors, axis=0)
bc_factors.sort_index(inplace=True)
bc_factors.to_csv(os.path.join(plots, 'bc_factors.csv'), index=True)
