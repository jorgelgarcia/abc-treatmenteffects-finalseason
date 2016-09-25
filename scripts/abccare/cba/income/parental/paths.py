import os
from treedict import TreeDict

filedir = os.path.join(os.path.dirname(__file__))
paths = TreeDict()


paths.abc = os.path.join(filedir, '..', '..', '..', '..', '..', 'data', 'abccare', 'extensions' ,'cba-iv' ,'abccare-parent.dta')
paths.cnlsy = os.path.join(filedir, '..', '..', '..', '..', '..', 'data', 'nlsy', 'extensions', 'abc-match-cnlsy', 'cnlsy-abc-match-parent.dta')
paths.psid = os.path.join(filedir, '..', '..', '..', '..', '..', 'data', 'psid', 'extensions', 'abc-match', 'psid-abc-match.dta')
paths.nlsy = os.path.join(filedir, '..', '..', '..', '..', '..', 'data', 'nlsy', 'extensions', 'abc-match-nlsy', 'nlsy-abc-match.dta')

paths.data = os.path.join(filedir,'hdf5')
paths.psid_bsid = os.path.join(filedir,'..', 'psid_sampling', 'psid_bsid.dta')
paths.nlsy_bsid = os.path.join(filedir,'..', 'nlsy_sampling', 'samples_nlsy.csv')
paths.cnlsy_bsid = os.path.join(filedir,'..', 'nlsy_sampling', 'samples_cnlsy.csv')

paths.rslts = os.path.join(filedir,'..', 'rslt', 'projections', 'parental')
