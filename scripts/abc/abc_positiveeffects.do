version 12.0
set more off
clear all
set matsize 11000

/*
Project :       ABC
Description:    plot estimates conditional on IQ
*This version:  April 18, 2016
*This .do file: Jorge L. Garcia
*This project : All except Seong, B. and CC. 
*/

// set environment variables (server)
global erc: env erc
global projects: env projects
global klmshare:  env klmshare
global klmmexico: env klmMexico
global googledrive: env googledrive

// set general locations
// do files
global scripts     = "$projects/abc-treatmenteffects-finalseason/scripts/"
// ready data
global dataresults = "$klmshare/JShea/forJLG/rslt-apr21"
global dataabccare = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
// output
global output      = "$projects/abc-treatmenteffects-finalseason/output/"

// cd into abc itt results
cd rslt_itt/abc_ate/rslt_itt

insheet using abc_outcomes.csv, clear
keep variable hyp
rename variable rowname
tempfile revsheet
save "`revsheet'", replace

foreach var in male female pooled {
	insheet using itt_`var'.csv, clear
	keep if ddraw == 0
	keep rowname itt_noctrl
	gen itt_pos = 0
	replace itt_pos = 1 if i
	merge 1:1 rowname using "`revsheet'" 
	drop if _merge != 3
	replace itt_noctrl = - itt_noctrl if hyp == "-"
	summ itt_pos
	local itt_pos`var' = r(mean)
}
