import cPickle as pkl
import os
import pandas as pd
import numpy as np
import pytabular as pytab
import itertools

from scipy.stats import percentileofscore
from paths import paths
from load_data import abccare
np.random.seed(seed=1234)

outcomes = pd.read_csv(os.path.join(paths.outcomes), index_col='variable')

attriters_male = [74, 78, 119]
attriters_female = [82, 96, 99, 121, 900, 906, 912, 914, 922, 9999]
attriters = attriters_male + attriters_female

crime_attrit = [9999, 70, 74, 75, 76, 78, 82, 900, 906,
                907, 909, 911, 912, 83, 87, 94, 97, 914,
                915, 921, 922, 99, 100, 102, 104, 105, 110,
                931, 934, 938, 941, 119, 120, 121, 126, 954]

for a in ['0', '1', '2', '3', '4', '7', '8', '10', '11']:
#for a in ['7']:
    
    #outcomes.age = outcomes.age.fillna('NA')
    if a == '0':
        rslt = pkl.load(open(os.path.join(paths.rslt, 'bootstrap_balance.pkl'), 'rb'))
    if a in ['1','2','3','4']:
        rslt = pkl.load(open(os.path.join(paths.rslt, 'bootstrap_balance_coh{}.pkl'.format(a)), 'rb'))
    if a == '7':
        rslt = pkl.load(open(os.path.join(paths.rslt, 'bootstrap_balance_crime.pkl'), 'rb'))        
    if a == '8':
        rslt = pkl.load(open(os.path.join(paths.rslt, 'bootstrap_balance_health.pkl'), 'rb'))        
    if a == '10':
        rslt = pkl.load(open(os.path.join(paths.rslt, 'bootstrap_balance_attrition.pkl'), 'rb'))        
    if a == '11':
        rslt = pkl.load(open(os.path.join(paths.rslt, 'bootstrap_balance_postattrition.pkl'), 'rb'))        
    rslt = rslt.astype(float)
        
    # Create alterantive index
    breps = rslt.index.get_level_values(0).max() + 1
    alt_ix = outcomes.set_index('block', append=True)
    alt_ixl = pd.concat([alt_ix for j in range(breps)], keys=[k for k in range(breps)], names =['draws']).index
    alt_ix = alt_ix.index
    order = pd.DataFrame([j for j in range(len(alt_ix))], index = alt_ix)
    order.columns = ['order']
    
    # obtain counts of treated and control for each table
    if a == '0':
        pooled_t = abccare.query('R==1')[outcomes.index].count().to_frame()
        male_t = abccare.query('male==1&R==1')[outcomes.index].count().to_frame()
        female_t = abccare.query('male==0&R==1')[outcomes.index].count().to_frame()
        counts_t = pd.concat([pooled_t, male_t, female_t], axis=1)
        counts_t.columns = pd.MultiIndex.from_product([['pooled', 'male', 'female'], [None], ['obs']], names=['sex', 'est', 'stat'])
        
        pooled_c = abccare.query('R==0')[outcomes.index].count().to_frame()
        male_c = abccare.query('male==1&R==0')[outcomes.index].count().to_frame()
        female_c = abccare.query('male==0&R==0')[outcomes.index].count().to_frame()
        counts_c = pd.concat([pooled_c, male_c, female_c], axis=1)        
        counts_c.columns = pd.MultiIndex.from_product([['pooled', 'male', 'female'], [None], ['att']], names=['sex', 'est', 'stat'])     
        
    if a in ['1', '2', '3', '4']:
    
        pooled_t = abccare.query('R==1&cohort=={}'.format(a))[outcomes.index].count().to_frame()
        male_t = abccare.query('male==1&R==1&cohort=={}'.format(a))[outcomes.index].count().to_frame()
        female_t = abccare.query('male==0&R==1&cohort=={}'.format(a))[outcomes.index].count().to_frame()
        counts_t = pd.concat([pooled_t, male_t, female_t], axis=1)
        counts_t.columns = pd.MultiIndex.from_product([['pooled', 'male', 'female'], [None], ['obs']], names=['sex', 'est', 'stat'])
        
        pooled_c = abccare.query('R==0&cohort=={}'.format(a))[outcomes.index].count().to_frame()
        male_c = abccare.query('male==1&R==0&cohort=={}'.format(a))[outcomes.index].count().to_frame()
        female_c = abccare.query('male==0&R==0&cohort=={}'.format(a))[outcomes.index].count().to_frame()
        counts_c = pd.concat([pooled_c, male_c, female_c], axis=1)        
        counts_c.columns = pd.MultiIndex.from_product([['pooled', 'male', 'female'], [None], ['att']], names=['sex', 'est', 'stat'])           

    if a in ['7']:
    
        pooled_t = abccare.drop(crime_attrit, axis=0).query('R==1')[outcomes.index].count().to_frame()
        male_t = abccare.drop(crime_attrit, axis=0).query('male==1&R==1')[outcomes.index].count().to_frame()
        female_t = abccare.drop(crime_attrit, axis=0).query('male==0&R==1')[outcomes.index].count().to_frame()
        counts_t = pd.concat([pooled_t, male_t, female_t], axis=1)
        counts_t.columns = pd.MultiIndex.from_product([['pooled', 'male', 'female'], [None], ['obs']], names=['sex', 'est', 'stat'])
        
        pooled_c = abccare.drop(crime_attrit, axis=0).query('R==0')[outcomes.index].count().to_frame()
        male_c = abccare.drop(crime_attrit, axis=0).query('male==1&R==0')[outcomes.index].count().to_frame()
        female_c = abccare.drop(crime_attrit, axis=0).query('male==0&R==0')[outcomes.index].count().to_frame()
        counts_c = pd.concat([pooled_c, male_c, female_c], axis=1)        
        counts_c.columns = pd.MultiIndex.from_product([['pooled', 'male', 'female'], [None], ['att']], names=['sex', 'est', 'stat'])      

    if a in ['8']:
    
        pooled_t = abccare.query('R==1&si34y_complete==1')[outcomes.index].count().to_frame()
        male_t = abccare.query('male==1&R==1&si34y_complete==1')[outcomes.index].count().to_frame()
        female_t = abccare.query('male==0&R==1&si34y_complete==1')[outcomes.index].count().to_frame()
        counts_t = pd.concat([pooled_t, male_t, female_t], axis=1)
        counts_t.columns = pd.MultiIndex.from_product([['pooled', 'male', 'female'], [None], ['obs']], names=['sex', 'est', 'stat'])
        
        pooled_c = abccare.query('R==0&si34y_complete==1')[outcomes.index].count().to_frame()
        male_c = abccare.query('male==1&R==0&si34y_complete==1')[outcomes.index].count().to_frame()
        female_c = abccare.query('male==0&R==0&si34y_complete==1')[outcomes.index].count().to_frame()
        counts_c = pd.concat([pooled_c, male_c, female_c], axis=1)        
        counts_c.columns = pd.MultiIndex.from_product([['pooled', 'male', 'female'], [None], ['att']], names=['sex', 'est', 'stat'])      

    if a in ['10']:
    
        pooled_t = abccare.loc[attriters][outcomes.index].count().to_frame()
        male_t = abccare.loc[attriters_male][outcomes.index].count().to_frame()
        female_t = abccare.loc[attriters_female][outcomes.index].count().to_frame()
        counts_t = pd.concat([pooled_t, male_t, female_t], axis=1)
        counts_t.columns = pd.MultiIndex.from_product([['pooled', 'male', 'female'], [None], ['obs']], names=['sex', 'est', 'stat'])
        
        pooled_c = abccare.drop(attriters, axis=0)[outcomes.index].count().to_frame()
        male_c = abccare.drop(attriters, axis=0).query('male==1')[outcomes.index].count().to_frame()
        female_c = abccare.drop(attriters, axis=0).query('male==0')[outcomes.index].count().to_frame()
        counts_c = pd.concat([pooled_c, male_c, female_c], axis=1)        
        counts_c.columns = pd.MultiIndex.from_product([['pooled', 'male', 'female'], [None], ['att']], names=['sex', 'est', 'stat'])      

    if a in ['11']:
    
        pooled_t = abccare.drop(attriters, axis=0).query('R==1')[outcomes.index].count().to_frame()
        male_t = abccare.drop(attriters, axis=0).query('male==1&R==1')[outcomes.index].count().to_frame()
        female_t = abccare.drop(attriters, axis=0).query('male==0&R==1')[outcomes.index].count().to_frame()
        counts_t = pd.concat([pooled_t, male_t, female_t], axis=1)
        counts_t.columns = pd.MultiIndex.from_product([['pooled', 'male', 'female'], [None], ['obs']], names=['sex', 'est', 'stat'])
        
        pooled_c = abccare.drop(attriters, axis=0).query('R==0')[outcomes.index].count().to_frame()
        male_c = abccare.drop(attriters, axis=0).query('male==1&R==0')[outcomes.index].count().to_frame()
        female_c = abccare.drop(attriters, axis=0).query('male==0&R==0')[outcomes.index].count().to_frame()
        counts_c = pd.concat([pooled_c, male_c, female_c], axis=1)        
        counts_c.columns = pd.MultiIndex.from_product([['pooled', 'male', 'female'], [None], ['att']], names=['sex', 'est', 'stat'])      
            
    counts = pd.concat([counts_c, counts_t], axis = 1)
    counts.set_index(alt_ix, inplace=True)

   
    # P-Values
    mean = rslt.groupby(level=['variable']).mean()
    mean = pd.concat([mean for j in range(breps)], keys=[k for k in range(breps)], names = ['draw'])    
    
    null = rslt - mean
    pval = (abs(null) >= abs(mean))
    pval[mean.isnull()] = np.nan
    pval = pval.mean(axis=0, level='variable')
    
    se = rslt.std(axis=0, level='variable')
    se = pd.concat([se for j in range(breps)], keys=[k for k in range(breps)], names = ['draw'])    

    # IMPLEMENT STEPDOWN
    # 1. Convert to t-Statistics
    null = null/se
    null.set_index(alt_ixl, inplace=True)
    null.sort_index(inplace = True)

    point = rslt.loc[0]   
    se = se.loc[0]   
    
    tstat = point/se
    tstat.set_index(alt_ix, inplace=True)
    tstat.sort_index(inplace=True)
    
    # 3. stepdown for main tables
    
    blocks = list(pd.Series(outcomes.block.values).unique())
    
    stepdown_dict = {}
    for sex in ['male', 'female', 'pooled']:
        stepdown_dict[sex] = pd.DataFrame([])
        for block in blocks:
            print "Stepdown test for %s, %s sample..." % (block, sex)        
            ix = null.loc[(slice(None), slice(None), block),:].index
            tix = list(itertools.product(ix.get_level_values(1).unique(), [block]))
            
            tmp_pval = pd.DataFrame([1 for j in range(len(tix))], index=tix, columns=['stepdown'])
            
            tmp_tstat = tstat.loc[tix, (sex, 'raw', 'diff')].copy()
            tmp_tstat = abs(tmp_tstat)
    
            # apply stepdown
            do_stepdown = 1
            while do_stepdown == 1:
                
                sd_dist = null.loc[ix, (sex, 'raw', 'diff')].groupby(level=[0,2]).max()
                sd_dist = abs(sd_dist.values)
                
                sd_ptest = lambda x: 1 - percentileofscore(sd_dist, x)/100            
                
                sd_pval_tmp = map(sd_ptest, list(tmp_tstat.values))
                sd_pval_tmp = pd.DataFrame(sd_pval_tmp, index=tix, columns=['stepdown'])
                
                # update p-values as necessary            
                tmp_pval.loc[tix,'stepdown'] = sd_pval_tmp.loc[tix,'stepdown']
                
                # see if we need to continue
                    
                if any(tmp_pval.loc[tix,:]<=0.1): # we set 10% level for stepdown
                    tix_drop = tmp_pval.loc[tix,:].loc[tmp_pval.loc[tix,:].stepdown <= 0.1,:].index # we set 10% level for stepdown
                    for k in list(tix_drop):
                        try:
                            ix = ix.drop(k[0], level=1)
                            tix = tix.remove(k)
                            tmp_tstat.drop(k, inplace=True)
                            
                        except:
                            pass
                    if tix == None:
                        stepdown_dict[sex] = pd.concat([stepdown_dict[sex], tmp_pval], axis = 0)
                        do_stepdown = 0    
               
                else:
                    stepdown_dict[sex] = pd.concat([stepdown_dict[sex], tmp_pval], axis = 0)
                    do_stepdown = 0
                    
    # merge together stepdown p-values
    tuples = [('pooled', 'diff', 'stepdown'), ('male', 'diff', 'stepdown'), ('female', 'diff', 'stepdown')]
    sd_multiix = pd.MultiIndex.from_tuples(tuples, names=['sex', 'est', 'stat']) 
    sdpval = pd.concat([stepdown_dict['pooled'],stepdown_dict['male'],stepdown_dict['female']], keys=['pooled', 'male', 'female'], axis=1)
    sdpval.columns = sd_multiix
    
    stats = pd.concat([point, pval], keys=['mean', 'pval'], names=['stat'], axis=1)
    stats.columns.names = ['stat', 'sex', 'met', 'est']
    stats = stats.reorder_levels(['sex', 'met', 'est', 'stat'], axis=1)
    
    ipw = stats.xs('ipw', axis=1, level='met')
    raw = stats.xs('raw', axis=1, level='met')
    raw.columns = ipw.columns
    stats = ipw.fillna(raw)

    # add differences to control mean
    for sex in ['male', 'female', 'pooled']:
        stats.loc[:,(sex, 'diff', 'mean')] = stats.loc[:,(sex, 'control', 'mean')] + stats.loc[:,(sex, 'diff', 'mean')]
    
    # remove naive p-values when thre are no obs. for treatment effects
    for sex in ['male', 'female', 'pooled']:
        ix = stats.ix[(stats[sex, 'control', 'mean']==0) & (stats[sex, 'diff', 'mean']==0)].index
        stats.loc[ix, (sex, 'diff', 'pval')] = np.nan
    
    # merge in stepdown p-vals
    stats.set_index(alt_ix, inplace=True)
    stats_main = pd.concat([stats, sdpval], axis=1)
        
    # prepare tables
    data = pd.concat([counts, stats_main], axis=1).sort_index(axis=1)    
    data.fillna('', inplace=True)
    data.index.names=['variable', 'block']
    
    # declare the columns you want to make your table
    columns = pd.MultiIndex.from_tuples(
    	[('pooled', None, 'att'), ('pooled', None, 'obs'), ('pooled', 'control', 'mean'), ('pooled', 'diff', 'mean'), ('pooled', 'diff', 'pval'), ('pooled', 'diff', 'stepdown'),
    	('male', None, 'att'), ('male', None, 'obs'), ('male', 'control', 'mean'), ('male', 'diff', 'mean'), ('male', 'diff', 'pval'), ('male', 'diff', 'stepdown'),
    	('female', None, 'att'), ('female', None, 'obs'), ('female', 'control', 'mean'), ('female', 'diff', 'mean'), ('female', 'diff', 'pval'), ('female', 'diff', 'stepdown'),],
    	names=['sex', 'est', 'stat'])
    
    data = data.join(order)
    data.sort('order', inplace=True)
    data.drop('order', axis=1, inplace=True)
    
    data = data.reindex(columns=columns)
    data.sortlevel(axis=1, inplace=True)
        
    # prepare table for pytabular
    data.index = outcomes.set_index(['label', 'age', 'category']).index
    
    '''APPENDIX TABLES: One Table for Each Sex Grouping'''
    
    def format_int(x):
        try:
            return '{:,.0f}'.format(x)
        except:
            return '{}'.format(x)

    def format_year(x):
        try:
            return '{:.0f}'.format(x)
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
    
       
    for sex in ['pooled']:  
        for i, cat in enumerate(outcomes.category.drop_duplicates().tolist()):
            
            ix = outcomes.set_index(['label', 'age']).query('category=="{}"'.format(cat))
            ix = ix.set_index(['category'], append=True).index
            tab = data.loc[ix, sex].reset_index()
            
            tab.drop('category', level=0, axis=1, inplace=True) 
            
            # declare headers, and join with table
            if a == '10':
                tab = [['', '', '', '', 'Observed', 'Attritted', '$p$-value', ''], ['Variable', 'Age', 'Obs.', 'Att.', 'Mean', 'Mean', 'Single $H_0$', 'Multiple $H_0$']] + tab.values.tolist()
            else:
                tab = [['', '', 'Control', 'Treated', 'Control', 'Treated', '$p$-value', ''], ['Variable', 'Age', 'Obs.', 'Obs.', 'Mean', 'Mean', 'Single $H_0$', 'Multiple $H_0$']] + tab.values.tolist()
    
            table = pytab.Table(tab)

            table.set_fontsize('scriptsize')    
                
            # set lines
            table[0, 6:].merge()
            table[1].set_lines(1)
            table[5].set_lines(1)
            table[2:, 0].set_alignment('l')
            table[2:, 1:].set_alignment('c')
            table[2:, 2:].set_alignment('c')
            table[2:, 2:3].set_formatter(format_int)
            table[2:, 4:-2].set_formatter(format_float)
            table[5:6, 4:-2].set_formatter(format_year)
            table[2:, -2:].set_formatter(format_pvalue)
            
            table.tabular = 1
            
            if a == '0':
                table.write(os.path.join(paths.apptables, 'baseline_balance'))
            if a in ['1','2','3','4']:
                table.write(os.path.join(paths.apptables, 'baseline_coh{}'.format(a)))
            if a == '7':
                table.write(os.path.join(paths.apptables, 'crime_balance'))
            if a == '8':
                table.write(os.path.join(paths.apptables, 'health_balance'))                
            if a == '10':
                table.write(os.path.join(paths.apptables, 'attrition_balance'))                
            if a == '11':
                table.write(os.path.join(paths.apptables, 'postattrition_balance'))                                
