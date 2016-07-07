import os
from treedict import TreeDict

filedir = os.path.join(os.path.dirname(__file__))

paths = TreeDict()
#paths.abccare = os.path.join(os.environ['klmshare'], 'Data_Central', 'Abecedarian', 'data', 'ABC-CARE', 'extensions', 'cba-iv', 'append-abccare_iv.dta')
paths.abccare = os.path.join(filedir, '..', '..', '..', 'data', 'abccare', 'extensions', 'cba-iv', 'append-abccare_iv.dta') # for testing
paths.maintables = os.path.join(filedir, '..','..','..', 'output')
paths.apptables = os.path.join(filedir, '..','..','..','AppOutput', 'Program')
paths.rslt = os.path.join(filedir, 'rslt')
paths.outcomes = os.path.join(filedir, 'outcomes.csv')
paths.samples = os.path.join(filedir, '..','..', 'misc', 'sampling', 'care_samples_1000.csv')
