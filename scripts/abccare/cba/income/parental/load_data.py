import os
import sys
from pandas.io.pytables import read_hdf
from treedict import TreeDict

from paths import paths

extrap = TreeDict()

'''Datasets'''

nlsy = read_hdf(os.path.join(paths.data, 'data.h5'), 'nlsy-labor')
psid = read_hdf(os.path.join(paths.data, 'data.h5'), 'psid-labor')
extrap = read_hdf(os.path.join(paths.data, 'data.h5'), 'extrap-labor')
abcd = read_hdf(os.path.join(paths.data, 'data.h5'), 'abc-mini')
