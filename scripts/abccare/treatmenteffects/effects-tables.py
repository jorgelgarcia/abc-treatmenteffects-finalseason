# -*- coding: utf-8 -*-
"""
Created on Fri Mar 11 15:17:41 2016

@author: jkcshea

Description: this file takes the estimates in .csv files and produces a series of
tables displaying various ITT estimates.

It also presents the count of socially positive treatment effects and conducts 
inference on those counts.

THINGS TO CLEAN UP:
- if in 'uniform category'---that list is empty
- labels for sex... don't you just ned to capitalize instead of use a dictionary?
- do you need to declare the 'main' dictionary for the outcomes tables twice? they're identical
- eventually you shoud remove the ABC/CARE options, it should always be for ABC + CARE.
"""

import os
import collections
import pandas as pd
import numpy as np
import pytabular as pytab
from scipy.stats import percentileofscore
from paths import paths 

# declare certain paths that you will need
filedir = os.path.join(os.path.dirname(__file__))
klmpath = os.environ['klmMexico'] + '/abccare/outputfiles/jun-24'

#global for ABC/CARE or just ABC
abc = 1
care =1
twosided = 0
visits = 0
schoolage = 0
tabular = 1

# declare blank paths to prevent errors
path_results = ''
path_outcomes= ''

# declare general options for paths and table notes
if abc == 1 and care == 0:
    pathext = 'abc'
    path_results = os.path.join(filedir, 'rslts-jun24/abc_ate/')
    path_outcomes = os.path.join(filedir, 'outcomes_abc.csv')
    controls = """the Apgar score 1 minute after birth, the HRI index, maternal IQ, an
indicator for teenage pregnancy of the mother, an indicator for the father being at 
home, and an indicator for having a grandmother residing in the same county"""
    abccare = 'abc'
    
if abc == 1 and care == 1:
    pathext = 'abccare'
    path_results = os.path.join(filedir, 'rslts-jun24/abccare_ate/')
    path_outcomes = os.path.join(filedir, 'outcomes_abccare.csv')
    controls = """Apgar scores 1 minute and 5 minutes after birth, the HRI index, maternal IQ,
an indicator for having a grandmother residing in the same county, and an index for the number
of relatives living in the same household"""
    abccare = 'abccare'
    
if abc == 0 and care == 1: 
    pathext = 'care'
    path_results = os.path.join(filedir, 'rslts-jun24/care_ate/')
    path_outcomes = os.path.join(filedir, 'outcomes_care.csv')
    controls = """Apgar scores 1 minute and 5 minutes after birth, an indicator for the subject 
being born prematurely, an indicator for the mother being married at baseline, an indicator for
teenage pregnancy of the mother, and an indicator for being born in the fall"""
    abccare = 'care'

# refine paths for cases of school-age treatment and home visits
if abc == 1 and care == 0 and schoolage == 1:
    pathext = 'abcsa'
    path_results = os.path.join(filedir, 'rslts-jun24/abcsa_ate/')

if abc == 0 and care == 1 and visits == 1 and twosided == 0:
    pathext = 'carefam'
    path_results = os.path.join(filedir, 'rslts-jun24/care_family/')

if abc == 0 and care == 1 and visits == 1 and twosided == 1:
    pathext = 'carefam_2sided'
    path_results = os.path.join(filedir, 'rslts-jun24/care_family/')

# declare suffix for file names
if schoolage == 1:
    abccare = abccare + 'sa'
if visits == 1:
    abccare = abccare + 'hv'
if twosided == 1:
    abccare = abccare + '2s'
    
# assert that paths are not blank
assert path_results != '', 'ERROR: blank path for .csv containing results'
assert path_outcomes != '', 'ERROR: blank path for .csv containing list of outcomes'

#=========================================
# Bring in estimates and necessary files
#=========================================

# bring in .csv with all labels and step-down groupings
outcomes = pd.read_csv(path_outcomes, index_col='variable')

'''
COMMENT:
What do you do with the error column? The error rows? 
Decide what to do with the error rows, and then drop the
error column
'''

# bring in all results
rslt_y = {}

for sex in ['pooled', 'male', 'female']:
    itt_all = pd.read_csv(os.path.join(path_results, 'itt', 'itt_{}.csv'.format(sex)), index_col=['rowname', 'draw', 'ddraw'])
    itt_p1 = pd.read_csv(os.path.join(path_results, 'itt', 'itt_{}_P1.csv'.format(sex)), index_col=['rowname', 'draw', 'ddraw'])    
    itt_p0 = pd.read_csv(os.path.join(path_results, 'itt', 'itt_{}_P0.csv'.format(sex)), index_col=['rowname', 'draw', 'ddraw'])
    
    matching_p1 = pd.read_csv(os.path.join(path_results, 'matching', 'matching_{}_P1.csv'.format(sex)), index_col=['rowname', 'draw', 'ddraw'])    
    matching_p0 = pd.read_csv(os.path.join(path_results, 'matching', 'matching_{}_P0.csv'.format(sex)), index_col=['rowname', 'draw', 'ddraw'])
    
    itt_all = itt_all.loc[:,['itt_noctrl', 'itt_ctrl', 'itt_wctrl']]
    rslt_p1 = pd.concat([itt_p1, matching_p1], axis=1).loc[:, ['itt_noctrl', 'itt_ctrl', 'itt_wctrl', 'epan_ipw', 'epan_N']]
    rslt_p0 = pd.concat([itt_p0, matching_p0], axis=1).loc[:, ['itt_noctrl', 'itt_ctrl', 'itt_wctrl', 'epan_ipw', 'epan_N']]
    
    rslt_y[sex] = pd.concat([itt_all, rslt_p1, rslt_p0], axis=1, keys=['pall', 'p1', 'p0'])
    
rslt_y = pd.concat(rslt_y, axis=1, keys=rslt_y.keys(), names=['sex', 'type', 'coefficient'])
rslt_y = rslt_y.reorder_levels(['draw', 'ddraw', 'rowname'])
rslt_y.index.names = ['draw', 'ddraw', 'variable']
rslt_y.sort_index(inplace=True)

# drop variables from outcomes.csv that we do not estimate things on
rslt_y.drop(['iq6y', 'si30y_cig_daily'], axis=0, level=2, inplace=True)
outcomes.drop(['iq6y', 'si30y_cig_daily'], axis=0, inplace=True)

ind_rslt_y = rslt_y.index.get_level_values(2).unique()
ind_outcomes = [i for i in outcomes.index if i in ind_rslt_y]
outcomes = outcomes.loc[ind_outcomes,:]
#outcomes = outcomes.loc[rslt_y.index.get_level_values(2).unique(),:]


# drop the t-score for mental health so we don't have 2
rslt_y.drop(outcomes.loc[outcomes.category=="Mental Health $t$-Score"].index, level=2, inplace=True)
outcomes.drop(list(outcomes.loc[outcomes.category=="Mental Health $t$-Score"].index), axis=0, inplace=True)


if abc == 1 and care == 1: # check these conditional drops
    abc_drop = ['ibr_coop0y6m', 'irb_coop1y', 'ibr_coop1y6m', 'ibr_coop2y']
    outcomes.drop(['ach12y', 'iq2y6m'], axis=0, inplace=True)
    rslt_y.drop(['ach12y', 'iq2y6m'], level=2, inplace=True)
    
if care == 1:
    care_drop = ['iq6y', 'iq15y', 'iq21y', 'factor_iq21',
                 'ach6y6m', 'ach7y', 'ach15y', 'ach21y', 'factor_achv21',
                 'adopted_ever', 'm_work21y']
    
    # first drop rows from rslt_y so the counts will be correct---we do this using outcomes.csv
    rslt_y.drop(care_drop, level=2, inplace=True)
    rslt_y.drop(list(outcomes.loc[outcomes.category=="Mother's Education"].index), level=2, inplace=True)
    rslt_y.drop(list(outcomes.loc[outcomes.category=="Child Behavior"].index), level=2, inplace=True)
    # now drop the rows from the outcomes.csv
    for dvar in care_drop:    
        try:        
            outcomes.drop(dvar, axis=0, inplace=True)
        except:
            pass
    outcomes.drop(list(outcomes.loc[outcomes.category=="Mother's Education"].index), axis=0, inplace=True)
    outcomes.drop(list(outcomes.loc[outcomes.category=="Child Behavior"].index), axis=0, inplace=True)

# blank out failed estimates
rslt_y.sortlevel(axis=1, inplace=True)
rslt_cols = ['itt_noctrl', 'itt_ctrl', 'itt_wctrl', 'epan_ipw']
rslt_y.loc[:, (slice(None), slice(None), rslt_cols)] = rslt_y.loc[:, (slice(None), slice(None), rslt_cols)].replace(0, nan)

#=========================================
# single-hypothesis tests
#=========================================

for agg in [0,1]:
    # obtain point estimate and null distribution
    if agg == 0:    
        tmp_rslt = rslt_y
    if agg == 1:
        tmp_names = rslt_y.index.names
        tmp_rslt = rslt_y.swaplevel(i=0, j=1, axis=0)
        tmp_rslt.index.names = tmp_names
        tmp_rslt.sort_index(inplace=True)
    
    mean = tmp_rslt.groupby(level=['variable', 'ddraw']).transform(lambda x: x.mean())
    null = tmp_rslt - mean
    
    # prepare to obtain p-values by expanding point estimate
    draw_max = int(tmp_rslt.index.get_level_values(0).unique().max())
    point_ext = pd.concat([tmp_rslt.loc[(0, slice(None), slice(None)), :] for j in range(draw_max + 1)], axis=0, keys=[k for k in range(draw_max + 1)], names=['newdraw'])
    point_ext.reset_index('draw', drop=True, inplace=True)
    point_ext.index.names = ['draw', 'ddraw','variable']
    #point_ext = point_ext.reorder_levels(['draw', 'ddraw', 'variable'])
    point_ext = point_ext.loc[null.index,:]
    
    # two-sided test for each individual effect
    if twosided == 1:
        null = null.abs()
        point_ext = point_ext.abs()   
    
    # obtain p-values
    less = (null <= point_ext); less[point_ext.isnull()] = np.nan
    less = less.mean(axis=0, level=['ddraw', 'variable'])
    
    pval_tmp = (null >= point_ext); pval_tmp[point_ext.isnull()] = np.nan
    pval_tmp = pval_tmp.mean(axis=0, level=['ddraw', 'variable'])
    pval_tmp.loc[(slice(None), outcomes.query('hyp == "-"').index), :] = less.loc[(slice(None), outcomes.query('hyp == "-"').index), :]
    pval_tmp.sortlevel(axis=1, inplace = True)
    pval_tmp.sort_index(inplace=True)

    if agg == 0:   
        # point estimates and standard errors
        point = rslt_y.sort_index().loc[(0,0,slice(None)), :]
        point.sortlevel(axis=1, inplace=True)
        point.reset_index(level=[0,1], drop=True, inplace=True)
        pval = pval_tmp.loc[(0, slice(None))]
        se = tmp_rslt.loc[(slice(None), 0, slice(None)),:].reset_index('ddraw', drop=True).std(level='variable') 
        
    if agg == 1:
        pval_cf = pval_tmp


#=========================================
# multiple-hypothesis tests
#=========================================

# 1. Convert to t-Statistics

mean = rslt_y.groupby(level=['variable', 'ddraw']).transform(lambda x: x.mean())
null = rslt_y - mean
null = null.loc[(slice(None), 0, slice(None)),:].reset_index('ddraw', drop=True)/se
null.sort_index(inplace=True)
null.loc[(slice(None), outcomes.query('hyp == "-"').index), :] = null.loc[(slice(None), outcomes.query('hyp == "-"').index), :] * -1

tstat = point/se
tstat.sort_index(inplace=True)
tstat.loc[outcomes.query('hyp == "-"').index, :] = tstat.loc[outcomes.query('hyp == "-"').index, :] * -1

# 2. create stepdown for tables
stepdown = pd.DataFrame([], columns=tstat.columns, index=tstat.index)
blocks = list(pd.Series(outcomes.block.values).unique())
blocks.remove(nan)

for block in blocks:
    print "Stepdown test for main tables, %s block..." % (block)
    # generate dataframe to store p-values for block of outcomes
    ix = list(outcomes.loc[outcomes.block==block,:].index)
    for coef in tstat.columns:
        # genreate dataframe to store t-statistics
        tmp_pval = pd.DataFrame([1 for j in range(len(ix))], index=ix)
        tmp_tstat = tstat.loc[ix, coef].copy()
        # apply stepdown
        do_stepdown = 1
        while do_stepdown == 1:
            sd_dist = null.loc[(slice(None), ix), coef].groupby(level=0).max().dropna()
            sd_ptest = lambda x: 1 - percentileofscore(sd_dist, x)/100
            sd_pval_tmp = map(sd_ptest, list(tmp_tstat))
            sd_pval_tmp = pd.DataFrame(sd_pval_tmp, index=ix)
            # update p-values as necessary            
            tmp_pval.loc[ix] = sd_pval_tmp.loc[ix]
            
            # determine if stepdown needs to continue (alpha of 0.10 is the threshold)
            if any(tmp_pval.loc[ix]<0.1):
                ix_drop = list(tmp_pval.loc[ix,0].loc[tmp_pval.loc[ix,0] < 0.1].index)
                ix = list(ix)
                for k in ix_drop:
                    try:
                        ix.remove(k)
                        tmp_tstat.drop(k, inplace=True)
                    except:
                        pass
                # end cycle if all hypotheses rejected
                if ix == []:
                    ix = tmp_pval.index
                    stepdown.loc[ix, coef] = tmp_pval.values
                    do_stepdown = 0                    
            # end cycle if no additional hypotheses rejected
            else:
                ix = tmp_pval.index
                stepdown.loc[ix, coef] = tmp_pval.values
                do_stepdown = 0                    

stepdown.fillna(pval, inplace=True)

#=========================================
# discount earnings variables
#=========================================
'''
# variables to discount
if care == 0:
    discount_vars = ['p_inc1y6m', 'p_inc2y6m', 'p_inc3y6m', 'p_inc4y6m', 'p_inc8y', 'p_inc12y', 
            'p_inc15y', 'si21y_inc_labor', 'si30y_inc_labor', 'si21y_inc_trans_pub',
            'si30y_inc_trans_pub']        
if care == 1:
    discount_vars = ['p_inc1y6m', 'p_inc2y6m', 'p_inc3y6m', 'p_inc4y6m',
                     'si21y_inc_labor', 'si30y_inc_labor', 'si21y_inc_trans_pub',
                     'si30y_inc_trans_pub']            

# generate discount index
discount_index = pd.Series([1.03 for j in range(len(discount_vars))], index=discount_vars)
discount_index.index.names = ['variable']
discount_index = 1 / (discount_index ** outcomes.loc[discount_vars].age.astype('float'))

discount_coefs = ['itt_noctrl', 'itt_ctrl', 'itt_wctrl', 'epan_ipw']

# apply discount index
point.loc[discount_vars,(slice(None), slice(None), discount_coefs)] = point.loc[discount_vars,(slice(None), slice(None), discount_coefs)].multiply(discount_index, axis="index")
'''

#=========================================
# combine tables (this dataframe is for making the tables)
#=========================================

data = pd.concat([point, pval, stepdown], keys = ['point', 'pval', 'sdpval'], names=['stat', 'variable'])
data = data.reorder_levels(['variable', 'stat'], axis=0)
data.sort_index(axis=0, inplace=True)

# blank out bad/unnecssary entries
data.fillna('', inplace=True)
notest_cols = ['epan_N', 'itt_noctrl_p', 'itt_noctrl_N', 'itt_ctrl_p', 'itt_ctrl_N', 'itt_wctrl_p', 'itt_wctrl_N']
data.loc[(slice(None), ['pval']), (slice(None), slice(None), notest_cols)] = ""

#=========================================
# prepare dataframes for combining function
#=========================================

N_point = rslt_y.loc[(slice(None),0, slice(None)),:].reset_index(level=1, drop=True)
category = outcomes.loc[:, ['category', 'hyp']].reset_index()
N_point = N_point.reset_index(level=0).merge(category, how='left', left_index=True, right_on='variable') 
N_point = N_point.rename(columns={'category':('category','',''), 'variable':('variable','',''), 'hyp':('hyp','','')})
N_point.set_index(['variable', 'draw', 'category'], inplace=True)
N_point.sortlevel(axis=1, inplace=True) 
N_point.sort_index(inplace=True)

# reverse signs so all effects are beneficial
N_point.loc[N_point.hyp=='+' ,:] = np.sign(N_point.loc[N_point.hyp=='+' ,:] * 1) * N_point.loc[N_point.hyp=='+' ,:].notnull()
N_point.loc[N_point.hyp=='-' ,:] = np.sign(N_point.loc[N_point.hyp=='-' ,:] * -1) * N_point.loc[N_point.hyp=='-' ,:].notnull()

# check that all N_point entries are either positive, negative, or 0 
assert all(N_point.isin([-1,0,1])), "ERROR: non-binary entry in 'N_point' matrix."

# generate total counts for the denominator
count_pos = N_point.replace(-1,0).groupby(level=[1,2], axis=0).sum().astype(int)
count_neg = N_point.replace(1,0).groupby(level=[1,2], axis=0).sum().abs().astype(int)
count_tot = N_point.replace(-1,1).groupby(level=[1,2], axis=0).sum().astype(int)

# generate matrix of 1s for beneficial treatment effects
count_pos = N_point.replace(-1,0).reorder_levels(['draw', 'variable', 'category']).sort_index()
# two-sided test for counts
if twosided == 1:
    count_pos = N_point.replace(-1,1).reorder_levels(['draw', 'variable', 'category']).sort_index()
count_pos.drop('hyp', axis=1, inplace=True)
count_pos.columns.names = ['sex', 'type', 'coefficient']
count_pos.sortlevel(axis=1, inplace=True)
count_pos.sort_index(inplace=True)
count_pos = count_pos[pval_cf.columns]
count_pos.columns = pval_cf.columns

# check the positives are counted correctly
assert all(count_pos.isin([0,1])), "ERROR: non-binary entry in 'count_pos' matrix."

# generate matrix of 1s for significant treatment effects
pdrop_ix = pval_cf.index.difference(count_pos.reset_index(level=2).index)
pval_cf.drop(pdrop_ix, inplace=True)
pval_cf.sort_index(inplace=True)
pval_cf.index = count_pos.index
count_sig = {}
aggcount_sig = {}
count_sig[100]= (pval_cf <= 1.00).astype(int)
count_sig[10] = (pval_cf <= 0.10).astype(int)
count_sig[5] = (pval_cf <= 0.05).astype(int)

total_count = 0

# generate null matrices for [counts by category] and [aggregate counts]
for a in [100, 10]:
    # limit counts by significance    
    count_sig[a] = (count_sig[a] * count_pos).fillna(0).astype(int)

    # aggregate counts, and convert aggregates into fractions
    aggcount_sig[a] = count_sig[a].groupby(level=[0], axis=0).sum()
    aggdenom = count_tot.groupby(level=[0],axis=0).sum()    
    aggdenom = aggdenom.loc[aggcount_sig[a].index, aggcount_sig[a].columns]
    
    if total_count == 0:
        total_count = aggdenom.loc[0, ('pooled', 'pall', 'itt_noctrl')]

    aggcount_sig[a] = aggcount_sig[a] / aggdenom
    aggcount_sig[a].loc[:,('draw','','')] = 0 # this is to collapse over and take the mean of later
    
    # convert categorical counts into fractions
    count_sig[a] = count_sig[a].groupby(level=[0,2], axis=0).sum()    
    denom = count_tot.loc[count_sig[a].index, count_sig[a].columns]
    count_sig[a] = count_sig[a]/denom


#=========================================
# Do hypothesis testing on counts by category
#=========================================

allcounts = collections.OrderedDict()
for cen_sig in [(0.5, 100), (0.1, 10)]:

    n = cen_sig[0]
    a = cen_sig[1]

    key = 'n{}a{}'.format(int(n*100),a)
    if a == 100:
        extra = ' ($H_0$: $\le$ {}\%)'.format(int(n*100))
    else:
        extra = ' ($H_0$: $\le$ {}\% $|$ {}\% Significance)'.format(int(n*100), a)
    
    # obtain point estimate and null distribution
    mean = count_sig[a].groupby(level=['category']).transform(lambda x: x.mean())
    null = count_sig[a] - mean + n
    
    # obtain standard error    
    se = null.std(level='category') * 100
    
    # prepare to obtain p-values by expanding point estimate
    draw_max = int(count_sig[a].index.get_level_values(0).unique().max())
    point_ext = pd.concat([count_sig[a].loc[(0, slice(None)), :] for j in range(draw_max + 1)], axis=0, keys=[k for k in range(draw_max + 1)], names=['newdraw'])
    point_ext.reset_index('draw', drop=True, inplace=True)
    point_ext.index.names = ['draw','variable']
    point_ext = point_ext.loc[null.index,:]
        
    # obtain p-values
    pval = (null >= point_ext).astype(int); pval[point_ext.isnull()] = np.nan
    pval = pval.mean(axis=0, level=['category'])
    pval.sortlevel(axis=1, inplace = True)
    pval.sort_index(inplace=True)
    
    # point estimates and standard errors
    point = count_sig[a].sort_index().loc[(0,slice(None)), :].reset_index(level=0, drop=True) * 100
    point.sortlevel(axis=1, inplace=True)
    
    # join tables
    allcounts[key] = pd.concat([point, pval, se], keys = ['point', 'pval', 'se'], names=['stat', 'category'])
    allcounts[key] = allcounts[key].reorder_levels(['category', 'stat'], axis=0)
    allcounts[key].sort_index(axis=0, inplace=True)
    if twosided == 0:        
        allcounts[key].loc[:,('label','','')] = '\% of Pos. TE{}'.format(extra)
    if twosided == 1:
        allcounts[key].loc[:,('label','','')] = '\% of Sig. TE{}'.format(extra)
    allcounts[key].loc[:,('age','','')] = np.nan
    
    # blank out bad/unnecssary entries
    allcounts[key].fillna('', inplace=True)
    allcounts[key].loc[(slice(None), ['pval']), (slice(None), slice(None), notest_cols)] = ""

allcounts = pd.concat(allcounts, axis=0)
allcounts.sort_index(inplace=True)
allcounts.sortlevel(inplace=True)



#=========================================
# Do hypothesis testing on counts, aggregated
#=========================================

aggcounts = collections.OrderedDict()
for cen_sig in [(0.5, 100), (0.1, 10)]:

    n = cen_sig[0]
    a = cen_sig[1]
        
    key = 'n{}a{}'.format(int(n*100),a)
    if a == 100:
        extra = ' ($H_0$: $\le$ {}\%)'.format(int(n*100))
    else:
        extra = ' ($H_0$: $\le$ {}\% $|$ {}\% Significance)'.format(int(n*100), a)
    
    # obtain point estimate and null distribution
    mean = aggcount_sig[a].groupby(by='draw').transform(lambda x: x.mean())
    null = aggcount_sig[a] - mean + n

    # obtain standard error    
    se = null.std(axis=0) * 100
            
    # prepare to obtain p-values by expanding point estimate
    draw_max = int(aggcount_sig[a].index.get_level_values(0).unique().max())
    point_ext = pd.concat([aggcount_sig[a].loc[0, :] for j in range(draw_max + 1)], axis=1, keys=[k for k in range(draw_max + 1)]).T
    point_ext = point_ext.drop('draw', axis=1).loc[null.index, null.columns]

    # obtain p-values
    pval = (null >= point_ext).astype(int); pval[point_ext.isnull()] = np.nan
    pval = pval.mean(axis=0)

    # point estimates and standard errors
    point = aggcount_sig[a].sort_index().loc[0, :] * 100

    # join tables
    aggcounts[key] = pd.concat([point, pval, se.T], axis=1, keys = ['point', 'pval', 'se'], names=['stat']).T
    aggcounts[key].loc[:,('label','','')] = '\% of Pos. TE{}'.format(extra)
    
    # blank out bad/unnecssary entries
    aggcounts[key].fillna('', inplace=True)
    aggcounts[key].loc['pval', (slice(None), slice(None), notest_cols)] = ""

aggcounts = pd.concat(aggcounts, axis=0)
aggcounts.sort_index(inplace=True)
aggcounts.sortlevel(inplace=True)

#=========================================
# Define functions required to make tables
#=========================================
def format_int(x):
    try:
        return '{:,.0f}'.format(x)
    except:
        return '{}'.format(x)

def format_float(x):
    try:
        if np.abs(x) > 99.999:
            return '{:,.0f}'.format(x)
        return '{:.3f}'.format(x)
    except:
        return '{}'.format(x)

def format_pvalue(x):
    try:
        if x <= 0.1:
            return '\\textbf{{({:.3f})}}'.format(x)
        elif x == '':
            return ''       
        return '({:.3f})'.format(x)
    except:
        return '({})'.format(x)

def format_sdpvalue(x):
    try:
        if x <= 0.1:
            return '\\textbf{{[{:.3f}]}}'.format(x)
        elif x == '':
            return ''       
        return '[{:.3f}]'.format(x)
    except:
        return '[{}]'.format(x)      


labels = {'pooled':'Males and Females', 'male':'Males', 
	'female':'Females'}

note = '''
Note: This table displays various estimates of the treatment effect of {}'s {}.
Column (1) displays the ITT, without accounting for any controls.
Column (2) displays the ITT conditioning on vector of controls, $X$, consisting of {}. We also apply IPW weights, $W$, to account for attrition.
Columns (3)--(4) are analogous to columns (1)--(2), but we restrict the control sample to subjects
who did not enroll in any alternative care.
Column (5) displys the matching estimate, where we use the Mahalanobis metric and Epanechnikov kernel
to match on controls $X$ listed above, and restrict the control sample to subjects who did not enroll
in any alternative care. Additionally, we apply IPW weights, $W$.
Columns (6)--(8) are analogous to Columns (3)--(5), except we restrict the control sample to subejcts
who did enroll in alternative care. {} 
Numbers in parentheses represent the $p$-value from a single hypothesis test, and are obtained from 
the empirical bootstrap distribution generated by 75 resamples of the original data. 
Bold $p$-values indicate significance at the 10\% level.
Blank point estimates indicate that we are unable to obtain estimates due to a lack of support in the data. 
'''

note_extension = '''The final three pairs of rows display the proportion of treatment effects in the table that are 
socially positive. The first row in each pair displays the percentage of treatment effects, and the
second row presents the inference.'''

if visits == 0 and schoolage == 0:
    caretype = 'center-based care'
if visits == 1:
    caretype = 'family education program'
if schoolage == 1:
    caretype = 'school age program'



#======================================
# MAIN TABLES: Males and Female Results
#======================================

uniform_categories = ['IQ Scores', 'HOME Scores', 'Parent Income', \
    '''Mother's Education''', 'Father at Home', '''Mother's Employment''', \
    'Adoption', 'Vitamin D Deficiency', 'Self-Reported Health']
uniform_categories = []


header = [['Variable', 'Age', '(1)', '(2)', '(3)', '(4)', '(5)', '(6)', '(7)', '(8)']]

main = {}
main['male'] = ['years_30y', 'si30y_inc_labor', 'si30y_works_job', 'ad34_mis', 'si34y_dia_bp', 'si34y_vitd_def', 'si34y_drugs']
main['female'] = ['iq12y', 'years_30y', 'si30y_inc_trans_pub', 'si30y_works_job', 'si30y_adlt_totinc', 'si34y_diab']
 

for t in [1,2]:    # t is for stepdown or no stepdown
    # prepare table for pytabular
    if t == 1:
        data_app = data.loc[(slice(None), ['point', 'pval']),:]
    if t == 2:
        data_app = data.loc[(slice(None), ['point', 'sdpval']),:]
       
    data_app.index = outcomes.loc[data_app.reset_index(level=1).index, ['label', 'age', 'category']].set_index(['label', 'age', 'category']).index    
   
    for sex in ['male', 'female']:

        rslt_columns = [(sex, 'pall', 'itt_noctrl'), (sex, 'pall', 'itt_wctrl'),
                        (sex, 'p0', 'itt_noctrl'), (sex, 'p0', 'itt_wctrl'), (sex, 'p0', 'epan_ipw'),
                        (sex, 'p1', 'itt_noctrl'), (sex, 'p1', 'itt_wctrl'), (sex, 'p1', 'epan_ipw')]

        ix = outcomes.loc[main[sex],:].set_index(['label', 'age'])
        ix = ix.set_index(['category'], append=True).drop(ix.set_index(['category'], append=True).index.difference(data_app.index)).index # TO ACCOUNT FOR CASES WHERE EFFECT COULD NTO BE ESTIMATED
        
        tab = data_app.loc[ix, rslt_columns].reset_index()
        tab.drop(['category'], axis=1, level=0, inplace=True)
        
        # create blank spaces for ages
        row = 1
        while row < tab.shape[0]:
            tab.iloc[row,1] = ''
            row += 2

        # prepare to create blank spaces for labels 
        row = 0
        vname = ''
        while row < tab.shape[0]:
            if tab.iloc[row,0] == vname:
                tab.iloc[row,0] = ''
            else:
                vname = tab.iloc[row,0]
            row += 1                     

        # set headers
        tab = header + tab.values.tolist()
            
        table = pytab.Table(tab)
        table.set_fontsize('scriptsize')                      

        if abc == 1 and care == 0:        
            table.set_caption('ABC {}, Selected Outcomes'.format(labels[sex]))
        
        if abc == 1 and care == 1:        
            table.set_caption('ABC and CARE {}, Selected Outcomes'.format(labels[sex]))

        if abc == 0 and care == 1:        
            table.set_caption('CARE {}, Selected Outcomes'.format(labels[sex]))            
        
        table.set_label('tab:ate_{}_{}_main'.format(abccare, sex))

        # Set lines and alignment
        table[0].set_lines(1)
        table[1:, 0].set_alignment('l')
        table[1:, 1:].set_alignment('c')  
        table[1:, 1].set_formatter(format_int)
                
        # format point estimates and p-values
        row = 1
        while row < table.shape[0]:
            table[row,2:].set_formatter(format_float) # format point estimate
            row += 1
            table[row,2:].set_formatter(format_pvalue) # format p-value
            row += 1

        # add table notes       
        if abc == 1 and care == 0: 
            table.add_note(note.format('ABC', caretype, controls,''))
        if abc == 1 and care == 1: 
            table.add_note(note.format('ABC/CARE', caretype, controls,''))
        if abc == 0 and care == 1: 
            table.add_note(note.format('CARE', caretype, controls, ''))            
        
        # decide on tabular environment
        if tabular == 1:
            table.tabular = 1

        # write out tables
        if t == 1:
            table.write(os.path.join(paths.tmp_tables, pathext, 'rslt_{}_main'.format(sex)))
        if t == 2:
            table.write(os.path.join(paths.tmp_tables, pathext, 'rslt_{}_main_sd'.format(sex)))
    
#=========================================
# Make Appendix Tables of results
#=========================================
"""
uniform_categories = ['IQ Scores', 'HOME Scores', 'Parent Income', \
    '''Mother's Education''', 'Father at Home', '''Mother's Employment''', \
    'Adoption', 'Vitamin D Deficiency', 'Self-Reported Health']
"""
uniform_categories = []

header = [['Variable', 'Age', '(1)', '(2)', '(3)', '(4)', '(5)', '(6)', '(7)', '(8)']]

for t in [1,2]:
    # prepare table for pytabular (t=1 regular p-values, t=2 stepdown)
    if t == 1:
        data_app = data.loc[(slice(None), ['point', 'pval']),:]
    if t == 2:
        data_app = data.loc[(slice(None), ['point', 'sdpval']),:]
       
    data_app.index = outcomes.loc[data_app.reset_index(level=1).index, ['label', 'age', 'category']].set_index(['label', 'age', 'category']).index
    
    for sex in ['pooled', 'male', 'female']:
        for i, cat in enumerate(outcomes.category.drop_duplicates().tolist()):
            
            rslt_columns = [(sex, 'pall', 'itt_noctrl'), (sex, 'pall', 'itt_wctrl'),
                            (sex, 'p0', 'itt_noctrl'), (sex, 'p0', 'itt_wctrl'), (sex, 'p0', 'epan_ipw'),
                            (sex, 'p1', 'itt_noctrl'), (sex, 'p1', 'itt_wctrl'), (sex, 'p1', 'epan_ipw')]
    
            ix = outcomes.set_index(['label', 'age']).query('category=="{}"'.format(cat))
            ix = ix.set_index(['category'], append=True).drop(ix.set_index(['category'], append=True).index.difference(data_app.index)).index # TO ACCOUNT FOR CASES WHERE EFFECT COULD NTO BE ESTIMATED
            
            tab = data_app.loc[ix, rslt_columns].reset_index()
            tab.drop(['category'], axis=1, level=0, inplace=True)
            
            # add in the counts
            if t == 1:
                add_count_order = [('n50a100',cat,'point'), ('n50a100',cat,'pval'),
                                   ('n10a10',cat,'point'), ('n10a10',cat,'pval')]
                add_counts = allcounts.loc[add_count_order, tab.columns].reset_index(drop=True)
                tab = tab.append(add_counts)
    
            # create blank spaces for ages
            if cat not in uniform_categories:
                row = 1
                while row < tab.shape[0]:
                    tab.iloc[row,1] = ''
                    row += 2
    
            # prepare to create blank spaces for labels 
            if cat not in uniform_categories:
                row = 0
                vname = ''
                while row < tab.shape[0]:
                    if tab.iloc[row,0] == vname:
                        tab.iloc[row,0] = ''
                    else:
                        vname = tab.iloc[row,0]
                    row += 1                     
    
            # set headers
            tab = header + tab.values.tolist()
                
            table = pytab.Table(tab)
            table.set_fontsize('scriptsize')                      
    
            if abc == 1 and care == 0:        
                table.set_caption('ABC Average Treatment Effects, {} \\\\ {}'.format(labels[sex], cat))
            
            if abc == 1 and care == 1:        
                table.set_caption('ABC/CARE Average Treatment Effects, {} \\\\ {}'.format(labels[sex], cat))
    
            if abc == 0 and care == 1:        
                table.set_caption('CARE Average Treatment Effects, {} \\\\ {}'.format(labels[sex], cat))            
            
            table.set_label('tab:ate_{}_{}_apx{}'.format(abccare, sex, i))
    
            # Set lines and alignment
            table[0].set_lines(1)
            table[1:, 0].set_alignment('l')
            table[1:, 1:].set_alignment('c')  
            table[1:, 1].set_formatter(format_int)

            if t == 1:            
                table[-5].set_lines(1)
                table[-4,0:2].merge()
                table[-2,0:2].merge()
            
            # format point estimates and p-values
            row = 1
            while row < table.shape[0]:
                table[row,2:].set_formatter(format_float) # format point estimate
                row += 1
                table[row,2:].set_formatter(format_pvalue) # format p-value
                row += 1
        
            # format counts
            if t == 1:        
                table[-4,2:].set_formatter(format_int)    
                table[-2,2:].set_formatter(format_int)    
    
            # Merging same-labeled rows in label column
            if cat in uniform_categories:
                row = 1
                begin = 1
                vals = np.array(table.original_content)
                while row < table.shape[0] - 1:
                    if vals[row, 0] == vals[row + 1, 0]:
                        pass
                    else:
                        table[begin:row + 1, 0].merge(force=True)
                        begin = row + 1
                        table[row].set_space_below('0.1cm')    
                    row += 1
                table[begin:, 0].merge(force=True)        
    
            # add table notes       
            if abc == 1 and care == 0: 
                table.add_note(note.format('ABC', caretype, controls, note_extension))
            if abc == 1 and care == 1: 
                table.add_note(note.format('ABC/CARE', caretype, controls, note_extension))
            if abc == 0 and care == 1: 
                table.add_note(note.format('CARE', caretype, controls, note_extension))            
    
            # decide on tabular environment
            if tabular == 1:
                table.tabular = 1
            
            # write out tables
            if t == 1:
                table.write(os.path.join(paths.tmp_tables, pathext, 'rslt_{}_cat{}'.format(sex, i)))
            if t == 2:
                table.write(os.path.join(paths.tmp_tables, pathext, 'rslt_{}_cat{}_sd'.format(sex, i)))            

#=========================================
# Make Counts Table, aggregated
#=========================================

counts_note ='''
Note: This table displays the percentage of the {} outcomes for which we estimate {}
treatment effects. For outcomes where a negative treatment effect is beneficial to the subjects
(e.g. prevalence of diabetes), we reverse the signs of treatment effects so that all beneficial 
effects have positive signs. We present the percentage of socially positive treatment effect estimates
with and without conditioning on being statistically significant at the 10\% level.
Column (1) correpsonds to the ITT, without accounting for any controls.
Column (2) correpsonds to the ITT conditioning on vector of controls, $X$, consisting of {}. We also apply IPW weights, $W$, to account for attrition.
Columns (3)--(4) are analogous to columns (1)--(2), but we restrict the control sample to subjects
who did not enroll in any alternative care.
Column (5) correpsonds to the matching estimate, where we use the Mahalanobis metric and Epanechnikov kernel
to match on controls $X$ listed above, and restrict the control sample to subjects who did not enroll
in any alternative care. Additionally, we apply IPW weights, $W$.
Columns (6)--(8) are analogous to Columns (3)--(5), except we restrict the control sample to subejcts
who did enroll in alternative care. 
Numbers in parentheses represent the $p$-value from a single hypothesis test, and are obtained from 
the empirical bootstrap distribution generated by 5,625 resamples of the original data. 
Bold $p$-values indicate significance at the 10\% level. Blank point estimates indicate that
we are unable to obtain estimates due to a lack of support in the data. 
'''

if twosided == 0:
    criteria = 'positive'
if twosided == 1:
    criteria = 'significant'


# prepare table for pytabular

header = [['', '(1)', '(2)', '(3)', '(4)', '(5)', '(6)', '(7)', '(8)']]

for sex in ['pooled', 'male', 'female']:
    
    rslt_columns = [('label', '', ''), 
                    (sex, 'pall', 'itt_noctrl'), (sex, 'pall', 'itt_wctrl'),
                    (sex, 'p0', 'itt_noctrl'), (sex, 'p0', 'itt_wctrl'), (sex, 'p0', 'epan_ipw'),
                    (sex, 'p1', 'itt_noctrl'), (sex, 'p1', 'itt_wctrl'), (sex, 'p1', 'epan_ipw')]
    
    if twosided == 0:
        agg_count_order = [('n50a100','point'), ('n50a100','pval'),
                           ('n10a10','point'), ('n10a10','pval')]
        agg_count_order_csv = [('n50a100','point'), ('n50a100','pval'), ('n50a100','se'),
                               ('n10a10','point'), ('n10a10','pval'), ('n10a10','se')]                           
        
    if twosided == 1:
        agg_count_order = [('n10a10','point'), ('n10a10','pval')]
        agg_count_order_csv = [('n10a10','point'), ('n10a10','pval'), ('n10a10','se')]

    # make csv files for creating plots and graphics    
    tab_csv = aggcounts.loc[agg_count_order_csv, rslt_columns].reset_index(drop=True)   
    tab_csv.columns = ['category', 'itt_noctrl', 'itt_wctrl', 
                           'itt_noctrl_p0', 'itt_wctrl_p0', 'epan_ipw_p0',
                           'itt_noctrl_p1', 'itt_wctrl_p1', 'epan_ipw_p1']
                       
    tab_csv.loc[:,'stat'] = 'point'
    tmp_k = 0
    for k in range(tab_csv.shape[0]/3):
        tmp_k += 1
        tab_csv.loc[tmp_k, 'stat'] = 'pval'
        tmp_k += 1        
        tab_csv.loc[tmp_k, 'stat'] = 'se'
        tmp_k += 1
    tab_csv.set_index(['category', 'stat'], append = True, inplace=True)
    tab_csv.index.names = ['index', 'category', 'stat']
    tab_csv.to_csv(os.path.join(klmpath, pathext, 'csv', 'rslt_{}_counts.csv'.format(sex)))   

    # make actual .tex table
    tab = aggcounts.loc[agg_count_order, rslt_columns].reset_index(drop=True)   
    
    tab.label = '' 
    if twosided == 0:   
        tab.loc[0,'label'] = "\% Pos. TE"
        tab.loc[2,'label'] = "\% Pos. TE $|$ 10\% Significance"
    if twosided == 1:   
        tab.loc[0,'label'] = "\% Sig. TE $|$ 10\% Significance"

    # prepare to create blank spaces for labels 
    row = 0
    vname = ''
    
    # set headers
    tab = header + tab.values.tolist()
        
    table = pytab.Table(tab)
    table.set_fontsize('scriptsize')                      

    if abc == 1 and care == 0:        
        table.set_caption('ABC Percentage of {} Treatment Effects, {}'.format(criteria.capitalize(), labels[sex]))

    if abc == 1 and care == 1:        
        table.set_caption('ABC/CARE Percentage of {} Treatment Effects, {}'.format(criteria.capitalize(), labels[sex]))
    
    if abc == 0 and care == 1:        
        table.set_caption('CARE Percentage of {} Treatment Effects, {}'.format(criteria.capitalize(), labels[sex]))
    
    table.set_label('tab:counts_{}_{}'.format(abccare, sex))

    # Set lines and alignment
    table[0].set_lines(1)
    table[1:, 0].set_alignment('l')
    table[1:, 1:].set_alignment('c')  
    
    # format point estimates and p-values
    row = 1
    while row < table.shape[0]:
        table[row,1:].set_formatter(format_int) # format point estimate
        row += 1
        table[row,1:].set_formatter(format_pvalue) # format p-value
        row += 1

    # add table notes
    table.add_note(counts_note.format(total_count, criteria, controls))

    # decide on tabular environment
    if tabular == 1:
        table.tabular = 1
    
    # write out tables
    table.write(os.path.join(paths.tmp_tables, pathext, 'rslt_{}_counts'.format(sex)))
    
    

#=========================================
# Make counts tables, by category
#=========================================

categories_order = ["IQ Scores","Achievement Scores","HOME Scores","Parent Income",
                    "Mother's Employment","Mother's Education","Father at Home",
                    "Adoption","Education","Employment and Income","Crime","Tobacco, Drugs, Alcohol",
                    "Self-Reported Health","Hypertension","Cholesterol","Diabetes",
                    "Vitamin D Deficiency","Obesity", "Mental Health","Child Behavior"]
                    #"Mental Health $t$-Score"

if care == 1:
    categories_order.remove("Child Behavior")
    categories_order.remove("Adoption")
    categories_order.remove("Mother's Education")    

header = [['Category', '(1)', '(2)', '(3)', '(4)', '(5)', '(6)', '(7)', '(8)', '']]

for sex in ['pooled', 'male', 'female']:
    
    rslt_columns = [('category', '', ''), 
                    (sex, 'pall', 'itt_noctrl'), (sex, 'pall', 'itt_wctrl'),
                    (sex, 'p0', 'itt_noctrl'), (sex, 'p0', 'itt_wctrl'), (sex, 'p0', 'epan_ipw'),
                    (sex, 'p1', 'itt_noctrl'), (sex, 'p1', 'itt_wctrl'), (sex, 'p1', 'epan_ipw')]

    for cen_sig in [(0.5, 100), (0.1, 10)]:

        n = int(cen_sig[0] * 100)
        a = cen_sig[1]

        # output to csv for making plots
        counts_pct = allcounts.reset_index(level=[2]).loc['n{}a{}'.format(n, a), rslt_columns]
        counts_num = count_tot.loc[(0, slice(None)), (sex, 'pall', 'itt_noctrl')].reset_index(level=0,drop=True)
        counts_cat = counts_pct.merge(pd.DataFrame(counts_num), how='left', left_index=True, right_index=True).drop(('category', '', ''), axis=1)
        counts_cat = counts_cat.loc[categories_order]
        
        tab_csv =  counts_cat.reset_index()
        tab_csv.columns = ['category', 'itt_noctrl', 'itt_wctrl', 
                           'itt_noctrl_p0', 'itt_wctrl_p0', 'epan_ipw_p0',
                           'itt_noctrl_p1', 'itt_wctrl_p1', 'epan_ipw_p1',
                           'outcomes']
                           
        tab_csv.loc[:,'stat'] = 'point'
        tmp_k = 0
        for k in range(tab_csv.shape[0]/3):
            tmp_k += 1
            tab_csv.loc[tmp_k, 'stat'] = 'pval'
            tmp_k += 1        
            tab_csv.loc[tmp_k, 'stat'] = 'se'
            tmp_k += 1
        tab_csv.set_index(['category', 'stat'], append = True, inplace=True)
        tab_csv.index.names = ['index', 'category', 'stat']
        tab_csv.to_csv(os.path.join(klmpath, pathext, 'csv', 'rslt_{}_counts_n{}a{}.csv'.format(sex, n, a)))
       
        # now make tables for paper       
        if a == 100:
            extra = '$H_0$: $\le$ {}\%'.format(n)
        else:
            extra = '$H_0$: $\le$ {}\% $|$ {}\% Significance'.format(n, a)
        counts_pct = allcounts.drop('se', level=2).reset_index(level=[2]).loc['n{}a{}'.format(n, a), rslt_columns]
        counts_num = count_tot.loc[(0, slice(None)), (sex, 'pall', 'itt_noctrl')].reset_index(level=0,drop=True)
        counts_cat = counts_pct.merge(pd.DataFrame(counts_num), how='left', left_index=True, right_index=True).drop(('category', '', ''), axis=1)
        counts_cat = counts_cat.loc[categories_order]
                           
        tab = counts_cat.reset_index()
        
        # prepare to create blank spaces for labels 
        row = 0
        vname = ''      
        while row < tab.shape[0]:
            if tab.iloc[row,0] == vname:
                tab.iloc[row,0] = ''
            else:
                vname = tab.iloc[row,0]
            row += 1                     
            
        row = 1
        while row < tab.shape[0]:
            tab.iloc[row,-1] = ''
            row += 2              
    
        # set headers
        tab = header + tab.values.tolist()
            
        table = pytab.Table(tab)
        table.set_fontsize('scriptsize')                      
    
        if abc == 1 and care == 0:        
            table.set_caption('ABC Percentage of {} Treatment Effects by Category, {} \\\\ {}'.format(criteria.capitalize(), labels[sex], extra))
    
        if abc == 1 and care == 1:        
            table.set_caption('ABC/CARE Percentage of {} Treatment Effects by Category, {} \\\\ {}'.format(criteria.capitalize(), labels[sex], extra))
        
        if abc == 0 and care == 1:        
            table.set_caption('CARE Percentage of {} Treatment Effects by Category, {} \\\\ {}'.format(criteria.capitalize(), labels[sex], extra))
        
        table.set_label('tab:counts_{}_{}_n{}a{}'.format(abccare, sex, n, a))
    
        # Set lines and alignment
        table[0].set_lines(1)
        table[1:, 0].set_alignment('l')
        table[1:, 1:].set_alignment('c')          
        
        # format point estimates and p-values
        row = 1
        while row < table.shape[0]:
            table[row,1:].set_formatter(format_int) # format point estimate
            row += 1
            table[row,1:].set_formatter(format_pvalue) # format p-value
            row += 1
        
        table[:,-1].set_formatter(format_int) # format count of outcomes
    
        # add table notes
        table.add_note(counts_note.format(total_count, criteria, controls))

        # decide on tabular environment
        if tabular == 1:
            table.tabular = 1
        
        # write out tables
        table.write(os.path.join(paths.tmp_tables, pathext, 'rslt_{}_counts_n{}a{}'.format(sex, n, a)))


#======================================
# PRESENTATION TABLES: Males and Female Results
#======================================


header = [['Variable', 'Age', '(1)', '(2)', '(3)', '(4)', '(5)', '(6)']]

main = {}
main['male'] = ['years_30y', 'si30y_inc_labor', 'si30y_works_job', 'ad34_mis', 'si34y_dia_bp', 'si34y_vitd_def', 'si34y_drugs']
main['female'] = ['iq12y', 'years_30y', 'si30y_inc_trans_pub', 'si30y_works_job', 'si30y_adlt_totinc', 'si34y_diab']


for t in [1,2]: # t is for stepdown
    # prepare table for pytabular
    if t == 1:
        data_app = data.loc[(slice(None), ['point', 'pval']),:]
    if t == 2:
        data_app = data.loc[(slice(None), ['point', 'sdpval']),:]
       
    data_app.index = outcomes.loc[data_app.reset_index(level=1).index, ['label', 'age', 'category']].set_index(['label', 'age', 'category']).index
    
        
    for sex in ['male', 'female']:
            
        rslt_columns = [(sex, 'pall', 'itt_noctrl'), (sex, 'pall', 'itt_wctrl'),
                        (sex, 'p0', 'itt_noctrl'), (sex, 'p0', 'epan_ipw'),
                        (sex, 'p1', 'itt_noctrl'), (sex, 'p1', 'epan_ipw')]

        ix = outcomes.loc[main[sex],:].set_index(['label', 'age'])
        ix = ix.set_index(['category'], append=True).drop(ix.set_index(['category'], append=True).index.difference(data_app.index)).index # TO ACCOUNT FOR CASES WHERE EFFECT COULD NOT BE ESTIMATED
        
        tab = data_app.loc[ix, rslt_columns].reset_index()
        tab.drop(['category'], axis=1, level=0, inplace=True)
        
        # create blank spaces for ages
        row = 1
        while row < tab.shape[0]:
            tab.iloc[row,1] = ''
            row += 2

        # prepare to create blank spaces for labels 
        row = 0
        vname = ''
        while row < tab.shape[0]:
            if tab.iloc[row,0] == vname:
                tab.iloc[row,0] = ''
            else:
                vname = tab.iloc[row,0]
            row += 1                     

        # set headers
        tab = header + tab.values.tolist()
            
        table = pytab.Table(tab)
        table.set_fontsize('scriptsize')
        table.set_label('tab:ate_{}_{}_main'.format(abccare, sex))

        # Set lines and alignment
        table[0].set_lines(1)
        table[1:, 0].set_alignment('l')
        table[1:, 1:].set_alignment('c')  
        table[1:, 1].set_formatter(format_int)
                
        # format point estimates and p-values
        row = 1
        while row < table.shape[0]:
            table[row,2:].set_formatter(format_float) # format point estimate
            row += 1
            table[row,2:].set_formatter(format_pvalue) # format p-value
            row += 1

        table.tabular = 1
        
        # write out tables
        if t == 1:
            table.write(os.path.join(paths.tmp_tables, pathext, 'rslt_{}_pres'.format(sex)))
        if t == 2:
            table.write(os.path.join(paths.tmp_tables, pathext, 'rslt_{}_pres_sd'.format(sex)))

#=========================================
# PRESENTATION TABLE: aggregate counts
#=========================================

if twosided == 0:
    criteria = 'positive'
if twosided == 1:
    criteria = 'significant'

# prepare table for pytabular

header = [['', '(1)', '(2)', '(3)', '(4)', '(5)', '(6)']]

for sex in ['pooled', 'male', 'female']:
    
    rslt_columns = [('label', '', ''), 
                    (sex, 'pall', 'itt_noctrl'), (sex, 'pall', 'itt_wctrl'),
                    (sex, 'p0', 'itt_noctrl'), (sex, 'p0', 'epan_ipw'),
                    (sex, 'p1', 'itt_noctrl'), (sex, 'p1', 'epan_ipw')]
    
    if twosided == 0:
        agg_count_order = [('n50a100','point'), ('n50a100','pval'), 
                           ('n10a10','point'), ('n10a10','pval')]
                           
    if twosided == 1:
        agg_count_order = [('n10a10','point'), ('n10a10','pval')]

    tab = aggcounts.loc[agg_count_order, rslt_columns].reset_index(drop=True)   
    
    tab.label = '' 
    if twosided == 0:   
        tab.loc[0,'label'] = "\% Pos. TE"
        tab.loc[2,'label'] = "\% Pos. TE $|$ 10\% Significance"
    if twosided == 1:   
        tab.loc[0,'label'] = "\% Sig. TE $|$ 10\% Significance"

    # prepare to create blank spaces for labels 
    row = 0
    vname = ''
    
    # set headers
    tab = header + tab.values.tolist()
        
    table = pytab.Table(tab)
    table.set_fontsize('scriptsize')                      

    # Set lines and alignment
    table[0].set_lines(1)
    table[1:, 0].set_alignment('l')
    table[1:, 1:].set_alignment('c')  
    
    # format point estimates and p-values
    row = 1
    while row < table.shape[0]:
        table[row,1:].set_formatter(format_int) # format point estimate
        row += 1
        table[row,1:].set_formatter(format_pvalue) # format p-value
        row += 1

    # decide on tabular environment
    table.tabular = 1
    
    # write out tables
    table.write(os.path.join(paths.tmp_tables, pathext, 'rslt_{}_counts_pres'.format(sex)))
