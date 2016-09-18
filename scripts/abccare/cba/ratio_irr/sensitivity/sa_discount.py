'''compute the rate of return'''
import os
import sys

import pandas as pd
import numpy as np
from copy import deepcopy

# Paths
sys.path.extend([os.path.join(os.path.dirname(__file__), '..')])
filedir = os.path.join(os.path.dirname(__file__))
plots = os.path.join(filedir, '..', 'rslt', 'sensitivity')
from cba_setup import bc_calc, makeflows
from cba_N import N

etype = 2
filled = makeflows(etype=etype)

# vary discount rate
bc_discount = pd.DataFrame([])
for r in np.arange(0,0.16,0.01) :
	bc_tmp = deepcopy(filled)
	output = bc_calc(bc_tmp, etype=etype, rate=r)
	
	output['rate'] = r
	bc_discount = pd.concat([bc_discount, output], axis=0)
 
	print 'B/C ratio for discount rate {} calculated.'.format(r)

bc_discount.sort_index(inplace=True)
bc_discount.to_csv(os.path.join(plots, 'bc_discount.csv'), index=True)
    
