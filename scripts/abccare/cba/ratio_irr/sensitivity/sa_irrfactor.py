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

from cba_setup import irr_calc, makeflows

etype = 2
filled = makeflows(etype=etype)

for sex in ['m', 'f', 'p']:
    filled['cc_{}'.format(sex)] = filled['ccpublic_{}'.format(sex)] + filled['ccprivate_{}'.format(sex)]
    filled['crime_{}'.format(sex)] = filled['crimepublic_{}'.format(sex)] + filled['crimeprivate_{}'.format(sex)]
    filled['health_{}'.format(sex)] = filled['health_private_{}'.format(sex)] + filled['health_public_{}'.format(sex)] 
    filled['transfer_{}'.format(sex)] = filled['inc_trans_pub_{}'.format(sex)] + filled['diclaim_{}'.format(sex)] + filled['ssclaim_{}'.format(sex)] + filled['ssiclaim_{}'.format(sex)]

components = ['inc_labor', 'inc_parent', 'transfer', 'edu', 'crime', 'costs', 'cc', 'health', 'qaly']
factors = np.arange(0,3.1,0.25)
combo = list(itertools.product(components, factors))

# vary factor: IRR
# applying factor to benefits        

def irr_factors(part, f):
    irr_tmp = deepcopy(filled)
    for sex in ['m', 'f', 'p']:
        irr_tmp['{}_{}'.format(part, sex)] = irr_tmp['{}_{}'.format(part, sex)] * f

    output = irr_calc(irr_tmp, components=components)        

    output['rate'] = f
    output['part'] = part
    
    print 'IRR for {} and factor {} calculated.'.format(part, f)
    return output

irr_factors = Parallel(n_jobs=25)(
	delayed(irr_factors)(part, f) for part, f in combo)
irr_factors = pd.concat(irr_factors, axis=0)
irr_factors.sort_index(inplace=True)
irr_factors.to_csv(os.path.join(plots, 'irr_factors_mp.csv'), index=True)