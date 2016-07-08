import os
import sys
from pandas.io.pytables import read_hdf
from treedict import TreeDict

sys.path.extend([os.path.join(os.path.dirname(__file__), '..')])
from paths import paths

extrap = TreeDict()

'''Datasets'''

psid = read_hdf(os.path.join(paths.data, 'data.h5'), 'psid-labor')
cnlsy = read_hdf(os.path.join(paths.data, 'data.h5'), 'cnlsy-labor')
nlsy = read_hdf(os.path.join(paths.data, 'data.h5'), 'nlsy-labor')
interp = read_hdf(os.path.join(paths.data, 'data.h5'), 'interp-labor')
extrap = read_hdf(os.path.join(paths.data, 'data.h5'), 'extrap-labor')
abcd = read_hdf(os.path.join(paths.data, 'data.h5'), 'abc-mini')
