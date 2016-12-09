# -*- coding: utf-8 -*-
"""
Created on Fri Mar 11 15:17:41 2016

@author: jkcshea

Description: this file takes the estimates in .csv files and produces a series of
tables displaying various ITT estimates. Regular and step down p-values are estimated.

The code also presents the count of socially positive treatment effects and conducts 
inference on those counts.

"""

import os
import collections
import pandas as pd
import numpy as np
import pytabular as pytab
from scipy.stats import percentileofscore
from pathcase2 import paths 

# declare certain paths that you will need
filedir = os.path.join(os.path.dirname(__file__))

# YK cross this out to generate the p_inc table
#path_results = os.path.join(filedir, 'rslts-jun25/abccare_ate/')
#path_outcomes = os.path.join(filedir, 'outcomes_cba_merged.csv')

path_results = os.path.join(filedir, 'rslt-case2/')
path_outcomes = os.path.join(filedir, '../outcomes/outcomes_cba_mainpaper.csv')

# provide option for two sided tests
twosided = 0


#=========================================
# Bring in estimates and necessary files
#=========================================

# bring in .csv with all labels and step-down groupings
outcomes = pd.read_csv(path_outcomes, index_col='variable')

# bring in all results
rslt_y = {}

for sex in ['pooled', 'male', 'female']:
    itt_all = pd.read_csv(os.path.join(path_results, 'itt', 'itt_{}_P10_case2.csv'.format(sex)), index_col=['rowname', 'draw', 'ddraw'])
    itt_p1 = pd.read_csv(os.path.join(path_results, 'itt', 'itt_{}_P1_case2.csv'.format(sex)), index_col=['rowname', 'draw', 'ddraw'])    
    itt_p0 = pd.read_csv(os.path.join(path_results, 'itt', 'itt_{}_P0_case2.csv'.format(sex)), index_col=['rowname', 'draw', 'ddraw'])
    
    matching_p1 = pd.read_csv(os.path.join(path_results, 'matching', 'matching_{}_P1_case2.csv'.format(sex)), index_col=['rowname', 'draw', 'ddraw'])    
    matching_p0 = pd.read_csv(os.path.join(path_results, 'matching', 'matching_{}_P0_case2.csv'.format(sex)), index_col=['rowname', 'draw', 'ddraw'])
    
    itt_all = itt_all.loc[:,['itt_noctrl', 'itt_ctrl', 'itt_wctrl']]
    rslt_p1 = pd.concat([itt_p1, matching_p1], axis=1).loc[:, ['itt_noctrl', 'itt_ctrl', 'itt_wctrl', 'epan_ipw', 'epan_N']]
    rslt_p0 = pd.concat([itt_p0, matching_p0], axis=1).loc[:, ['itt_noctrl', 'itt_ctrl', 'itt_wctrl', 'epan_ipw', 'epan_N']]
    
    rslt_y[sex] = pd.concat([itt_all, rslt_p1, rslt_p0], axis=1, keys=['pall', 'p1', 'p0'])
    
rslt_y = pd.concat(rslt_y, axis=1, keys=rslt_y.keys(), names=['sex', 'type', 'coefficient'])
rslt_y = rslt_y.reorder_levels(['draw', 'ddraw', 'rowname'])
rslt_y.index.names = ['draw', 'ddraw', 'variable']
rslt_y.sort_index(inplace=True)

# drop factors
factors = ['factor_iq5','factor_iq12','factor_iq21','factor_achv12','factor_achv21','factor_home',
'factor_pinc','factor_mwork','factor_meduc','factor_fhome','factor_educ','factor_emp',
'factor_crime','factor_tad','factor_shealth','factor_hyper','factor_chol','factor_diabetes',
'factor_obese','factor_bsi','factor_ext_p','factor_ext_e','factor_ext_t','factor_agr_p',
'factor_agr_e','factor_agr_t','factor_nrt_p','factor_nrt_e','factor_cns_p','factor_cns_e',
'factor_cns_t','factor_opn_e','factor_opn_t','factor_act_p']

for dvar in factors:
    try:
        rslt_y.drop(dvar, axis=0, level=2, inplace=True)
    except:
        pass

ind_rslt_y = rslt_y.index.get_level_values(2).unique()
ind_outcomes = [i for i in outcomes.index if i in ind_rslt_y]
outcomes = outcomes.loc[ind_outcomes,:]
#outcomes = outcomes.loc[rslt_y.index.get_level_values(2).unique(),:]

# blank out failed estimates
rslt_y.sortlevel(axis=1, inplace=True)
rslt_cols = ['itt_noctrl', 'itt_ctrl', 'itt_wctrl', 'epan_ipw']
rslt_y.loc[:, (slice(None), slice(None), rslt_cols)] = rslt_y.loc[:, (slice(None), slice(None), rslt_cols)].replace(0, np.nan)


#=========================================
# single-hypothesis tests
#=========================================

'''
We now obtain the p-values. There are two p-values we are interested in. One is
the p-value generated across the 'big'/'outer' bootstrap, which is displayed in 
the table of treatment effects. This corresponds to agg == 0 in the loop ('agg' 
refers to the 'aggregated counts' from the combining function).

The second p-value of interest is the p-value for each outer draw. This is estimated
when agg == 1.
'''
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

   
    # Select the negative outcomes   
    invoutcomes = {}
    for coef in tmp_rslt.columns:
        # generate dataframe to store t-statistics
        tmp_rslt_coef = tmp_rslt.loc[(0, 0, slice(None)), coef]
        neg_index = tmp_rslt_coef < 0
        tmp_rslt_neg = tmp_rslt_coef[neg_index]
        invoutcomes['{}'.format(coef)] = tmp_rslt_neg.index.get_level_values(2).unique()

    # prepare to obtain p-values by expanding point estimate
    draw_max = int(tmp_rslt.index.get_level_values(0).unique().max())
    point_ext = pd.concat([tmp_rslt.loc[(0, slice(None), slice(None)), :] for j in range(draw_max + 1)], axis=0, keys=[k for k in range(draw_max + 1)], names=['newdraw'])
    point_ext.reset_index('draw', drop=True, inplace=True)
    point_ext.index.names = ['draw', 'ddraw','variable']
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
	
    if twosided == 0:
        for coef in tmp_rslt.columns:	
            pval_tmp.loc[(slice(None), invoutcomes['{}'.format(coef)]), coef] = less.loc[(slice(None), invoutcomes['{}'.format(coef)]), coef]
    
    pval_tmp.sortlevel(axis=1, inplace = True)
    pval_tmp.sort_index(inplace=True)

    # obtain point estimates, standard errors, and the regular p-values for the ATE tables
    if agg == 0:   
        point = rslt_y.sort_index().loc[(0,0,slice(None)), :]
        point.sortlevel(axis=1, inplace=True)
        point.reset_index(level=[0,1], drop=True, inplace=True)
        pval = pval_tmp.loc[(0, slice(None))]
        se = tmp_rslt.loc[(slice(None), 0, slice(None)),:].reset_index('ddraw', drop=True).std(level='variable') 
    
    # obtain the p-values to determine significance for the combining functino (hence, "_cf")    
    if agg == 1:
        pval_cf = pval_tmp


#=========================================
# step down, multiple hypotheses tests
#=========================================

# 1. Convert distribution of results to t-Statistics
mean = rslt_y.groupby(level=['variable', 'ddraw']).transform(lambda x: x.mean())
null = rslt_y - mean
for coef in tmp_rslt.columns:	
    null.loc[(slice(None), 0, invoutcomes['{}'.format(coef)]), coef] = null.loc[(slice(None), 0, invoutcomes['{}'.format(coef)]), coef] * -1 
null = null.loc[(slice(None), 0, slice(None)),:].reset_index('ddraw', drop=True)/se
null.sort_index(inplace=True)

tstat = point/se
tstat.sort_index(inplace=True)
for coef in tmp_rslt.columns:	
    tstat.loc[invoutcomes['{}'.format(coef)], coef] = tstat.loc[invoutcomes['{}'.format(coef)], coef] * -1   

# 2. provide blocks and dictionary to estimate/store stepdown results
stepdown = pd.DataFrame([], columns=tstat.columns, index=tstat.index)
blocks = list(pd.Series(outcomes.block.values).unique())

#blocks.remove(np.nan)

for block in blocks:
	print "Stepdown test for main tables, %s block..." % (block)
	
	# generate dataframe to store p-values for block of outcomes
	ix = list(outcomes.loc[outcomes.block==block,:].index)
	for coef in tstat.columns:
		
		# generate dataframe to store t-statistics
		tmp_pval = pd.DataFrame([1 for j in range(len(ix))], index=ix)
		tmp_tstat = tstat.loc[ix, coef].copy()
		
		# sort t-statistics in a descending order and save the indices as a list
		tmp_tstat.sort(axis=1, ascending = False, inplace=True)
		tmp_tstat_list = list(tmp_tstat.index)
		print "printing tmp_tstat_list"
		print tmp_tstat_list

		# make dictionaries for the step-down p-values
		sd_pval_tmp = {} 
		storeval = {}
		
		# perform step-down method
		for i in range(0,len(tmp_tstat_list)):
			
			# select the max across each bootstrap
			sd_dist = null.loc[(slice(None), ix), coef].groupby(level=0).max()
			
			# count the cases where the selected max is greater than the T-statistics of our interest
			countone = sum(1 for item in sd_dist if tmp_tstat[i] <= item)

			# calculate the temporary p-value
			sd_pval_tmp[i] = (countone+1.0)/(1.0+101.0)
			
			# store p-value according to step-down conditions
			if i == 0:
				tmp_pval.loc[tmp_tstat_list[i]] = sd_pval_tmp[i]
				storeval[i] = sd_pval_tmp[i]
			if i != 0:
				tmp_pval.loc[tmp_tstat_list[i]] = max(sd_pval_tmp[i], storeval[i-1])
				storeval[i] = max(sd_pval_tmp[i], storeval[i-1])
			if np.isnan(point.loc[ix, coef][tmp_tstat_list[i]]):
				print "Printing if NA"
				print np.isnan(point.loc[ix, coef][tmp_tstat_list[i]])
				tmp_pval.loc[tmp_tstat_list[i]] = np.nan
			
			# consecutively drop the outcome with highest T statistics
			ix = list(ix)
			ix.remove(tmp_tstat_list[i])
			
			# Fill stepdown dataframe if i = len(tmp_tstat_list) 
			if i == len(tmp_tstat_list) - 1: 
				ix = tmp_pval.index
				stepdown.loc[ix, coef] = tmp_pval.values
				
'''		(Previous step-down algorithm: not implemented anymore)
        # perform stepdown method
        do_stepdown = 1
        while do_stepdown == 1:
            sd_dist = null.loc[(slice(None), ix), coef].groupby(level=0).max().dropna()
            sd_ptest = lambda x: 1 - percentileofscore(sd_dist, x)/100
            sd_pval_tmp = map(sd_ptest, list(tmp_tstat))
            sd_pval_tmp = pd.DataFrame(sd_pval_tmp, index=ix)
            # update p-values as the stepdown procedure continues
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
'''

# for variables we do not perform stepdown on, fill in stepdown matrix of p-value with regular p-values
stepdown.fillna(pval, inplace=True)

#=========================================
# combine point estimate and p-value tables (this dataframe is for making the tables)
#=========================================

data = pd.concat([point, pval, stepdown], keys = ['point', 'pval', 'sdpval'], names=['stat', 'variable'])
data = data.reorder_levels(['variable', 'stat'], axis=0)
data.sort_index(axis=0, inplace=True)

# blank out bad/unnecssary entries
data.fillna('', inplace=True)
notest_cols = ['epan_N', 'itt_noctrl_p', 'itt_noctrl_N', 'itt_ctrl_p', 'itt_ctrl_N', 'itt_wctrl_p', 'itt_wctrl_N']
data.loc[(slice(None), ['pval']), (slice(None), slice(None), notest_cols)] = ""


#=========================================
# Define functions required to make latex tables
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


     
#=========================================
# Make Appendix Tables of results
#=========================================

header = [['Variable', 'Age', '(1)', '(2)', '(4)', '(5)', '(7)', '(8)']]
for t in [1,2]:
    # prepare table for pytabular (t=1 regular p-values, t=2 stepdown)
    if t == 1:
        data_app = data.loc[(slice(None), ['point', 'pval']),:]
    if t == 2:
        data_app = data.loc[(slice(None), ['point', 'sdpval']),:]
       
    # set the index of the dataframes according to outcomes.csv
    data_app.index = outcomes.loc[data_app.reset_index(level=1).index, ['label', 'age', 'category']].set_index(['label', 'age', 'category']).index
    
    # now make tables looping throuh sex and outcome categories
    for sex in ['pooled', 'male', 'female']:
        for i, cat in enumerate(outcomes.category.drop_duplicates().tolist()):
            
            # select the columns of results that you want
            rslt_columns = [(sex, 'pall', 'itt_noctrl'), (sex, 'pall', 'itt_wctrl'),
                            (sex, 'p0', 'itt_wctrl'), (sex, 'p0', 'epan_ipw'),
                            (sex, 'p1', 'itt_wctrl'), (sex, 'p1', 'epan_ipw')]
    
            ix = outcomes.set_index(['label', 'age']).query('category=="{}"'.format(cat))
            ix = ix.set_index(['category'], append=True).drop(ix.set_index(['category'], append=True).index.difference(data_app.index)).index # TO ACCOUNT FOR CASES WHERE EFFECT COULD NTO BE ESTIMATED

            tab = data_app.loc[ix, rslt_columns].reset_index()
            tab.drop(['category'], axis=1, level=0, inplace=True)
            
            # append the combining functions to the table
            '''
            if t == 1:
                add_count_order = [('n50a100',cat,'point'), ('n50a100',cat,'pval'),
                                   ('n10a10',cat,'point'), ('n10a10',cat,'pval')]
                add_counts = allcounts.loc[add_count_order, tab.columns].reset_index(drop=True)
                tab = tab.append(add_counts)
            '''
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
    
            # Set lines and alignment
            table[0].set_lines(1)
            table[1:, 0].set_alignment('l')
            table[1:, 1:].set_alignment('c')  
            table[1:, 1].set_formatter(format_int)

            # only set line for combining functions if we are not doing stepdown            
            '''
            if t == 1:            
                table[-5].set_lines(1)
                table[-4,0:2].merge()
                table[-2,0:2].merge()
            '''
            
            # format point estimates and p-values
            row = 1
            while row < table.shape[0]:
                table[row,2:].set_formatter(format_float) # format point estimate
                row += 1
                table[row,2:].set_formatter(format_pvalue) # format p-value
                row += 1
        
            # format combining function results if we are not using stepdown
            '''            
            if t == 1:        
                table[-4,2:].set_formatter(format_int)    
                table[-2,2:].set_formatter(format_int)    
            '''
    
            table.tabular = 1
            
            # write out tables
            if t == 1:
                table.write(os.path.join(paths.apptables, 'rslt_{}_cat{}_case2'.format(sex, i)))
            if t == 2:
                table.write(os.path.join(paths.apptables, 'rslt_{}_cat{}_case2_sd'.format(sex, i)))     