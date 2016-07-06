from pandas.io.stata import StataReader


from paths import paths

reader = StataReader(paths.abccare)
abccare = reader.data(convert_dates=False, convert_categoricals=False)
abccare.id.fillna(9999, inplace=True) # This is to include the chidl with missing ID
abccare = abccare.dropna(subset=['id']).set_index('id')
abccare = abccare.sort_index()

abccare.drop(abccare.loc[(abccare.RV==1) & (abccare.R==0)].index, inplace=True)

# use same variable for income between CARE and ABC
#abccare.loc[abccare.program==0, 'p_inc0'] = abccare.loc[abccare.program==0, 'hh_inc0']

