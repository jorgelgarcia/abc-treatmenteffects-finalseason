version 12.0
set more off
clear all
set matsize 11000
set maxvar  32000

/*
Project		ABC and CARE CBA
Date 		June 30, 2016
Author		Joshua Shea
Description	This .do file generates the bootstraps for the baseline tables
		(bootstrapping in python is kind annoying, doesn't include 
		clustering and strata)
*/

* confirm you are running from the correct folder
global filedir: pwd
if strpos("$filedir", "scripts") == 0 & strpos("$filedir", "misc") == 0 & strpos("$filedir", "sampling") == 0 {
	di as error "ERROR: Must run code in the directory it is saved in."
	exit
}

* set environment variables
global projects: env projects
global klmshare:  env klmshare

* load in function
include sampling_function

* load data
*use13 "${klmshare}/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/append-abccare_iv.dta", clear
use "/home/jkcshea/Documents/cehd/projects/abc-treatmenteffects-finalseason/data/abccare/extensions/cba-iv/append-abccare_iv.dta"

* restrict data to what we need
keep id abc family male

* deal with child with missing ID
replace id = 9999 if missing(id)
sort abc id 

* declare number of bootstraps you want
global bootstraps 1000

* perform sampling for ABC + CARE
preserve
sampler, breps($bootstraps) strata(male) cluster(family)
outsheet using "abccare_samples_${bootstraps}.csv", comma names replace
restore

* perform sampling for ABC
preserve
sampler, breps($bootstraps) strata(male) cluster(family) program("abc")
outsheet using "abc_samples_${bootstraps}.csv", comma names replace
restore

* perform sampling for CARE
preserve
sampler, breps($bootstraps) strata(male) cluster(family) program("care")
outsheet using "care_samples_${bootstraps}.csv", comma names replace
restore

