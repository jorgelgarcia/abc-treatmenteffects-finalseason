import os
from treedict import TreeDict

filedir = os.path.join(os.path.dirname(__file__))
paths = TreeDict()

'''
# Server Paths (but these don't work on Acropolis)
paths.abc = os.path.join(os.environ['klmshare'], 'Data_Central', 'Abecedarian', 'data', 'ABC-CARE', 'extensions', 'cba-iv', 'append-abccare_iv.dta')
paths.nlsy = os.path.join(os.environ['klmshare'], 'Data_Central', 'data-repos', 'nlsy', 'extensions', 'abc-match-nlsy', 'nlsy-abc-match.dta')
paths.cnlsy = os.path.join(os.environ['klmshare'], 'Data_Central', 'data-repos', 'nlsy', 'extensions', 'abc-match-cnlsy', 'cnlsy-abc-match.dta')
paths.psid = os.path.join(os.environ['klmshare'], 'Data_Central', 'data-repos', 'psid', 'extensions', 'abc-match')
'''

paths.abc = os.path.join(filedir, '..', '..', '..', '..', 'data', 'abccare', 'extensions' ,'cba-iv' ,'append-abccare_iv.dta')
paths.cnlsy = os.path.join(filedir, '..', '..', '..', '..', 'data', 'nlsy', 'extensions', 'abc-match-cnlsy', 'cnlsy-abc-match.dta')
paths.psid = os.path.join(filedir, '..', '..', '..', '..', 'data', 'psid', 'extensions', 'abc-match', 'psid-abc-match.dta')
paths.nlsy = os.path.join(filedir, '..', '..', '..', '..', 'data', 'nlsy', 'extensions', 'abc-match-nlsy', 'nlsy-abc-match.dta')

paths.data = os.path.join(filedir, 'hdf5')
paths.psid_bsid = os.path.join(filedir, 'psid_sampling', 'psid_bsid.dta')
paths.nlsy_bsid = os.path.join(filedir, 'nlsy_sampling', 'samples_nlsy.csv')
paths.cnlsy_bsid = os.path.join(filedir, 'nlsy_sampling', 'samples_cnlsy.csv')

paths.rslts = os.path.join(filedir, 'rslt', 'projections')
