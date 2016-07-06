'''compute the rate of return'''
import os
import sys
import pandas as pd

from copy import deepcopy

# Paths
sys.path.extend([os.path.join(os.path.dirname(__file__), '..')])
filedir = os.path.join(os.path.dirname(__file__))
plots = os.path.join(filedir, '..', 'rslt', 'sensitivity')

from cba_setup import bc_calc, makeflows

rate_range = [0, 0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75, 3]
#rate_range = [0,1]

'''
1: "ITT", no controls
2: ITT, with controls and weights
3: P=0, "ITT" no controls
4: P=0, "ITT" with controls  and weights
5: P=0, matching
6: P=1, "ITT" no controls
7: P=1, "ITT" with controls  and weights
8: P=1, matching
'''

etype = 2
filled = makeflows(etype=etype)

## vary DWL: BC
bc_dwl = pd.DataFrame([])
for d in rate_range:
    bc_tmp = deepcopy(filled)
    for sex in ['m', 'f', 'p']:
        for part in ['inc_trans_pub_{}'.format(sex), 'diclaim_{}'.format(sex), 'ssclaim_{}'.format(sex), 'ssiclaim_{}'.format(sex)]:
            bc_tmp[part] = bc_tmp[part] * (d/0.5)
        for part in ['edu_{}'.format(sex)]:
            bc_tmp[part].loc[(sex, slice(None), slice(None)), slice('c0','c18')] = \
                bc_tmp[part].loc[(sex, slice(None), slice(None)), slice('c0','c18')] * ((1 + d)/1.5)
        for part in ['ccpublic_{}'.format(sex), 'crimepublic_{}'.format(sex), 'health_public_{}'.format(sex), 'costs_{}'.format(sex)]:
            bc_tmp[part]  = bc_tmp[part] * ((1+d)/1.5)

    output = bc_calc(bc_tmp)
    
    output['rate'] = d
    bc_dwl = pd.concat([bc_dwl, output], axis=0)
            
    print 'B/C Ratio for MCW {} calculated.'.format(d)

bc_dwl.sort_index(inplace=True)
bc_dwl.to_csv(os.path.join(plots, 'bc_dwl.csv'), index=True)

print bc_dwl