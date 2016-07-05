import os
from treedict import TreeDict

filedir = os.path.join(os.path.dirname(__file__))

paths = TreeDict()
#paths.abccare = os.path.join(os.environ['klmshare'], 'Data_Central', 'Abecedarian', 'data', 'ABC-CARE', 'extensions', 'cba-iv', 'append-abccare_iv.dta')
paths.maintables = os.path.join(filedir, '..','..','..','output')
paths.apptables = os.path.join(filedir, '..','..','..','AppResOutput', 'abccare')
paths.csvtables = os.path.join(filedir, '..','..','..','AppResOutput', 'csv')
paths.klmmexico = os.environ['klmMexico']


