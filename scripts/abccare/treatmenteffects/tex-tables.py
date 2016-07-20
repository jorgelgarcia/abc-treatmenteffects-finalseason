# -*- coding: utf-8 -*-
"""
Created on Wed Mar 16 09:27:24 2016

@author: jkcshea
"""
from paths import paths
import pandas as pd
import os

filedir = os.path.join(os.path.dirname(__file__))

# declare general options for paths and table notes
pathext = 'AppResOutput/abccare/'
program = 'abccare'
path_outcomes = os.path.join(filedir, 'outcomes_cba.csv')

# bring in .csv with all labels and step-down groupings
outcomes = pd.read_csv(path_outcomes, index_col='variable')
#outcomes.drop(list(outcomes.loc[outcomes.category=="Mental Health $t$-Score"].index), axis=0, inplace=True)

# command for outputing the tables of treatment effects
command = '''
	\\begin{{table}}[H]
     \\caption{{Treatment Effects on {}, {} Sample}}
     \\label{{table:{}_rslt_{}_cat{}{}}}
	\\input{{{}rslt_{}_cat{}{}}}
	\\end{{table}} 
'''

# command for outputing the tables of aggregate counts
command_counts = '''
	\\begin{{table}}[H]
     \\caption{{Combining Functions, {} Sample}} 
     \\label{{table:{}_rslt_{}_counts}}
	\\input{{{}rslt_{}_counts_all}}
	\\end{{table}}  
'''

# command for outputing the tables for counts by category
command_counts_cat = '''
	\\begin{{table}}[H]
     \\caption{{Combining Functions by Category{}, {} Sample}} 
     \\label{{table:{}_rslt_{}_counts_n{}a{}}}
	\\input{{{}rslt_{}_counts_n{}a{}_all}}
	\\end{{table}}   
'''

"""
# We don't display the main tables in the appendix
command_main = '''
\\begin{{center}}
	\\input{{{}rslt_{}_main{}}}
\\end{{center}}
'''
"""

f = open(os.path.join(paths.apptables, '..', '1_abccare.tex'), 'w')

head = '''
\\input{Preamble} \n
\\title{ABC Treatment Effects: Preliminary Estimates} \n
\\date{\\today} \n
\\begin{document} \n
\\maketitle \n
\\tableofcontents \n
\\clearpage \n\n
'''
# write in head
#f.write(head)

# column spacing
f.write('\\def\\arraystretch{0.6}\n\n')
f.write('\\setlength\\tabcolsep{0.3em}\n\n')


f.write('\\subsection{{Combining Functions, Aggregated}}\n\n')
# write in all other models
for sex in ['pooled', 'male', 'female']:
    pass
    f.write(command_counts.format(sex.capitalize(), program, sex, pathext, sex))
f.write('\\clearpage\n\n')

f.write('\\subsection{{Combining Functions, by Category}}\n\n')
for sex in ['pooled', 'male', 'female']:
    for cen_sig in [(0.5, 100), (0.1, 10)]:
        if cen_sig == (0.5, 100):
            extra=''
        if cen_sig == (0.1, 10):
            extra=' $|$ 10\\% Significance'            
        n = int(cen_sig[0] * 100)
        a = cen_sig[1]
        f.write(command_counts_cat.format(extra, sex.capitalize(), program, sex, n,a, pathext, sex, n, a))

f.write('\\clearpage\n\n')

# write in all other models
for sex in ['pooled', 'male', 'female']:
    f.write('\\subsection{{Treatment Effects for {} Sample}}\n\n'.format(sex.capitalize()))
    for i, cat in enumerate(outcomes.category.drop_duplicates().tolist()):
        f.write(command.format(cat, sex.capitalize(), program, sex, i, '', pathext, sex, i, ''))

f.write('\\clearpage\n\n')

# write in all other models
for sex in ['pooled', 'male', 'female']:
    f.write('\\subsection{{Treatment Effects for {} Sample, Step Down}}\n\n'.format(sex.capitalize()))
    for i, cat in enumerate(outcomes.category.drop_duplicates().tolist()):
        f.write(command.format(cat, sex.capitalize(), program, sex, i, '_sd', pathext, sex, i, '_sd'))
f.write('\\clearpage\n\n')

#f.write('\\end{document}')
f.close()