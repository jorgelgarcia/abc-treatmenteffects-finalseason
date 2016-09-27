import os
import sys

from pandas.io.stata import StataReader
from pandas.io.pytables import HDFStore
import pandas as pd

from paths import paths
from variables import cols

def unique_list(seq):
   set = {}
   map(set.__setitem__, seq, [])
   return set.keys()


if not os.path.exists(paths.data):
	os.mkdir(paths.data)

'''Load and Cache Datasets
   -----------------------

Notes:
- Ensures no overlap in id
- Trims observations with any labor income over $300,000 (U.S., 2014)
'''

#--------------------------------------------------------------------

print "Loading PSID"
reader = StataReader(paths.psid)
psid = reader.read(convert_dates=False, convert_categoricals=False)
psid = psid.dropna(subset=['id']).set_index('id')

# Trimming
inc = psid.filter(regex='^inc_labor[0-9][0-9]')
psid = psid.loc[psid.male == 0]
psid = psid.loc[psid.black == 1]
psid = psid.loc[((inc < inc.quantile(0.90)) | (inc.isnull())).all(axis=1)]

# Interpolating
plong = pd.wide_to_long(psid[inc.columns].reset_index(), 
    ['inc_labor'], i='id', j='age').sort_index()
plong = plong.interpolate(limit=5)
pwide = plong.unstack()
pwide.columns = pwide.columns.droplevel(0)
pwide.columns = ['{}{}'.format('inc_labor', a) for a in pwide.columns]
psid[pwide.columns] = pwide

# Dropping
psid = psid.loc[:, cols.extrap.keep]
#.dropna(subset=cols.extrap.keep, axis=0)
#
psid.loc[:,'inc_labor_mean'] = psid.loc[:, cols.extrap.outcomes].mean(axis=1)

# + inc.columns.tolist()
psid = psid.reset_index()
psid['id'] = psid['id'].astype(int)
psid = psid.set_index('id', drop=True)

#--------------------------------------------------------------------

print "Loading NLSY"
reader = StataReader(paths.nlsy)
nlsy = reader.read(convert_dates=False, convert_categoricals=False)
nlsy = nlsy.dropna(subset=['id']).set_index('id')

# Trimming
inc = nlsy.filter(regex='^inc_labor[0-9][0-9]')
nlsy = nlsy.loc[nlsy.male == 0]
nlsy = nlsy.loc[nlsy.black == 1]
nlsy = nlsy.loc[((inc < inc.quantile(0.90)) | (inc.isnull())).all(axis=1)]

# Interpolating
nlong = pd.wide_to_long(nlsy[inc.columns].reset_index(), 
    ['inc_labor'], i='id', j='age').sort_index()
nlong = nlong.interpolate(limit=5)
nwide = nlong.unstack()
nwide.columns = nwide.columns.droplevel(0)
nwide.columns = ['{}{}'.format('inc_labor', a) for a in nwide.columns]
nlsy[nwide.columns] = nwide

# Dropping
nlsy = nlsy.loc[:, cols.extrap.keep]
# + inc.columns.tolist()
#subset=cols.extrap.keep, axis=0

nlsy.loc[:,'inc_labor_mean'] = nlsy.loc[:, cols.extrap.outcomes].mean(axis=1)

nlsy = nlsy.reset_index()
nlsy['id'] = nlsy['id'].astype(int)
nlsy = nlsy.set_index('id', drop=True)


extrap = pd.concat([psid, nlsy], axis=0, keys=('psid', 'nlsy'), names=('dataset', 'id'))
print extrap.shape
#--------------------------------------------------------------------

print "Loading ABC"
reader = StataReader(paths.abc)
abcd = reader.read(convert_dates=False, convert_categoricals=False)
abcd.id.fillna(9999, inplace = True)
abcd = abcd.set_index('id')
abcd.drop(abcd.loc[(abcd.RV==1) & (abcd.R==0)].index, inplace=True)

inc = abcd.filter(regex='^inc_labor[0-9][0-9]')
along = pd.wide_to_long(abcd[inc.columns].reset_index(), ['inc_labor'], i='id', j='age').sort_index()
along = along.interpolate(limit=5)
awide = along.unstack()
awide.columns = awide.columns.droplevel(0)
awide.columns = ['{}{}'.format('inc_labor', a) for a in awide.columns]
abcd[awide.columns] = awide

abcd = abcd.loc[:,unique_list(['R'] + cols.interpABC.keep)]
print abcd
print "Storing Datasets in HDF5 Format"

datasets = [
	('psid-labor', psid), 
	('nlsy-labor', nlsy),
	('extrap-labor', extrap),
	('abc-mini', abcd)
    ]

store = HDFStore(os.path.join(paths.data, 'data.h5'))

for name, d in datasets:
	d.to_hdf(os.path.join(paths.data, 'data.h5'), key=name)

store.close()