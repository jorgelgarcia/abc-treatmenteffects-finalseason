'''compute the rate of return'''
import os
import sys
from joblib import Parallel, delayed
import pandas as pd
from copy import deepcopy

# Paths
sys.path.extend([os.path.join(os.path.dirname(__file__), '..')])
filedir = os.path.join(os.path.dirname(__file__))
plots = os.path.join(filedir, '..', 'rslt', 'sensitivity')

from cba_setup import irr_calc, makeflows

rate_range = [0, 0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75, 3]
#rate_range = [0, 1]

etype = 2
filled = makeflows(etype=etype)

# vary DWL: IRR
irr_dwl = pd.DataFrame([])
def irr_dwl(d):
    irr_tmp = deepcopy(filled)
    for sex in ['m', 'f', 'p']:
        for part in ['inc_trans_pub_{}'.format(sex), 'diclaim_{}'.format(sex), 'ssclaim_{}'.format(sex), 'ssiclaim_{}'.format(sex)]:
            irr_tmp[part] = irr_tmp[part] * (d/0.5)
        for part in ['edu_{}'.format(sex)]:
            irr_tmp[part].loc[(sex, slice(None), slice(None)), slice('c0','c18')] = \
                irr_tmp[part].loc[(sex, slice(None), slice(None)), slice('c0','c18')] * ((1 + d)/1.5)
        for part in ['ccpublic_{}'.format(sex), 'crimepublic_{}'.format(sex), 'health_public_{}'.format(sex), 'costs_{}'.format(sex)]:
            irr_tmp[part]  = irr_tmp[part] * ((1+d)/1.5)

    output = irr_calc(irr_tmp)
    
    output['rate'] = d
            
    print 'IRR for MCW {} calculated.'.format(d)
    
    return output

irr_dwl = Parallel(n_jobs=25)(
	delayed(irr_dwl)(d) for d in rate_range)
irr_dwl = pd.concat(irr_dwl, axis=0)
irr_dwl.sort_index(inplace=True)
irr_dwl.to_csv(os.path.join(plots, 'irr_dwl.csv'), index=True)

