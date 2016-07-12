/*--------------------------------------------
Date	June 11, 2016
Author	Joshua Shea
Project	ABC Cost Benefit Analysis

This code prepares the data to estimate the benefits
in labor income. This is really a temporary file, as
the estimates will be done in Julia.
--------------------------------------------*/

clear all
set maxvar 32000
set seed 1
set more off


* set up paths
global current "C:\Users\YuKyung\abc-treatmenteffects-finalseason\scripts\abccare\cba\health\treatmenteffects-julia"
global results	"~/abc-cba/analysis/health/rslt"
global base "$current/.."
global data "$current/../../../../../data/abccare/extensions/fam-merge"
global dofiles "$current"
global results "$current/../rslt"
global atecode "$current/../../../juliafunctions"


global projects: env projects

* read in functions
cd "${atecode}"
run epanechnikov
run lipwweights
run matching
run itt
run writematrix

* set up number of bootstraps and controls
global itt 1	// matching estimator is the default
global breps 1	// remember to minus 1
global areps 3	// remember to minus 1
global controls hrabc_index apgar1 apgar5 hh_sibs0y grandma_county has_relatives male
global ipwvars_all apgar1 apgar5 prem_birth
global component health_private_surv
global factors = 0
global deaths = 1

* perform estimates
cd "${dofiles}"
do data
if $itt == 0 do bootstrap_matching
if $itt == 1 do bootstrap_itt2

