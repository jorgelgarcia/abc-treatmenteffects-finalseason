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
global base	"~/abc-cba"
global abc	"~/abc-cba/data/abccare/extensions/fam-merge"
global dofiles	"~/abc-cba/analysis/health/code/stata"
global results	"~/abc-cba/analysis/health/rslt"

global projects: env projects
global atecode	"~/abc-care/scripts/controlcontamination/atecode"

* read in functions
cd "${atecode}"
run epanechnikov
run lipwweights
run matching
run itt
run writematrix

* set up number of bootstraps and controls
global itt 0	// matching estimator is the default
global breps 74	// remember to minus 1
global areps 74	// remember to minus 1
global controls hrabc_index apgar1 apgar5 hh_sibs0y grandma_county has_relatives male
global ipwvars_all apgar1 apgar5 prem_birth
global component health_private_surv
global factors = 0
global deaths = 1

* perform estimates
cd "${dofiles}"
do data
if $itt == 0 do bootstrap_matching
if $itt == 1 do bootstrap_itt

