import os
from treedict import TreeDict

filedir = os.path.join(os.path.dirname(__file__))

paths = TreeDict()
#paths.abccare = os.path.join(os.environ['klmshare'], 'Data_Central', 'Abecedarian', 'data', 'ABC-CARE', 'extensions', 'cba-iv', 'append-abccare_iv.dta')
paths.abccare = os.path.join(filedir, '..', '..', '..', 'data', 'abccare', 'extensions', 'cba-iv', 'append-abccare_iv.dta') # for testing
#paths.outcomes = os.path.join(filedir, '..', 'outcomes', 'outcomes.csv')
paths.outcomes = os.path.join(filedir, '..', 'outcomes', 'outcomes_p_inc.csv')
paths.instruments = os.path.join(filedir, 'instruments.csv')
paths.controls = os.path.join(filedir, 'controls.csv')

