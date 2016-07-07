import os
import sys
from pandas.io.pytables import read_hdf
from treedict import TreeDict

sys.path.extend([os.path.join(os.path.dirname(__file__), '..')])
from paths import paths

extrap = TreeDict()

psid = read_hdf(os.path.join(paths.data, 'data.h5'), 'psid-transfer')
cnlsy = read_hdf(os.path.join(paths.data, 'data.h5'), 'cnlsy-transfer')
nlsy = read_hdf(os.path.join(paths.data, 'data.h5'), 'nlsy-transfer')
interp = read_hdf(os.path.join(paths.data, 'data.h5'), 'interp-transfer')
extrap = read_hdf(os.path.join(paths.data, 'data.h5'), 'extrap-transfer')
abcd = read_hdf(os.path.join(paths.data, 'data.h5'), 'abc-mini')