import os
from treedict import TreeDict

filedir = os.path.join(os.path.dirname(__file__))

paths = TreeDict()
paths.abc = os.path.join(filedir, '..', '..', '..', '..', 'data/abc/append-abccare_iv_onlyabc.dta')
paths.abccare = os.path.join(filedir, '..', '..', '..', '..', 'data/append-abccare_iv.dta')
paths.care = os.path.join(filedir, '..', '..', '..', '..', 'data/care/append-abccare_iv_onlycare.dta')
paths.maintables = os.path.join(filedir, '..','..','..','output')
paths.apptables = os.path.join(filedir, '..','..','..','AppResOutput', 'abccare')
paths.klmmexico = os.environ['klmMexico']


