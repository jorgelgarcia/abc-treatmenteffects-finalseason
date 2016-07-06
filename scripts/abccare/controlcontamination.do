version 12.0
set more off
clear all
set matsize 11000
set maxvar  32000

/*
Project :       ABC, CARE Treatment Effects
Description:    this .do file compares ABC and CARE to PSID
*This version:  April 8, 2015
*This .do file: Jorge L. Garcia
*/

// set environment variables (server)
global erc: env erc
global projects: env projects
global klmshare:  env klmshare
global klmmexico: env klmMexico
global googledrive: env googledrive

// set general locations
// do files
global scripts    = "$projects/abc-treatmenteffects-finalseason/scripts/"
// ready data
global datapsid    = "$klmshare/Data_Central/data-repos/psid/base/"
global dataabccare = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
// output
global output     = "$projects/abc-treatmenteffects-finalseason/output/"

// abc
// open data
cd $dataabccare
use append-abccare_iv.dta, clear

// replace dc_mo_pre = 0 if dc_mo_pre == 2
sort    Q
replace Q = Q/60
cumul   Q if program=="abc" & treat == 0, gen(cdf_Q) 
summ    P if program=="abc" & treat == 0
// replace dc_mo_pre = 52 if dc_mo_pre >= 52
keep if program == "abc" & treat == 0
keep Q cdf_Q program treat 

// care
// open data
cd $dataabccare
use append-abccare_iv.dta, clear

// replace dc_mo_pre = 0 if dc_mo_pre == 2
sort    Q
replace Q = Q/60
cumul   Q if program=="abc" & treat == 0, gen(cdf_Q) 
summ    P if program=="abc" & treat == 0
// replace dc_mo_pre = 52 if dc_mo_pre >= 52
keep if program == "abc" & treat == 0
keep P Q cdf_Q program treat random male
tempfile abc_cc
save "`abc_cc'"

// describe
summ P if male == 1 & treat == 0 & P == 0
local mABC = round(100*r(mean),.01)
local mABC = r(N)
summ P if male == 0 & treat == 0 & P == 0
local fABC = round(100*r(mean),.001)
local fABC = r(N)

// care
// open data
cd $dataabccare
use append-abccare_iv.dta, clear

replace Q = 0 if dc_mo_pre == 2 & random == 3
replace P = 0 if dc_mo_pre == 2 & random == 3
summ P if random == 3
summ P if random == 0
sort    Q
replace Q = Q/60
cumul   Q if program=="care" & random  == 0, gen(cdf_Q_pre_control)
sort    Q
cumul   Q if program=="care" & random  == 3, gen(cdf_Q_fc)

keep if program == "care" & (random == 0 | random == 3)
keep P Q cdf_Q_pre_control cdf_Q_fc program treat male random
tempfile care_cc
save "`care_cc'"

// describe
summ P if male == 1 & random == 0 & P == 0
local mCARE = round(100*r(mean),.01)
local mCARE = r(N)
summ P if male == 0 & random == 0 & P == 0
local fCARE = round(100*r(mean),.01)
local fCARE = r(N)
append using "`abc_cc'"


#delimit
twoway (line cdf_Q              Q if program=="abc", lwidth(vthick) lcolor(gs0))
       (line cdf_Q_pre_control  Q if program=="care", lwidth(vthick) lpattern(dash) lcolor(gs0))
      , 
		  legend(label(1 "ABC") label(2 "CARE") position(12))
		  xlabel(, grid glcolor(gs14)) ylabel(0[.1]1, angle(h) glcolor(gs14))
		  xtitle("Proportion of Months in Alternative Preschools, Control Group") ytitle(Cumulative Density Function)
		  graphregion(color(white)) plotregion(fcolor(white)) 
		  note("[No Alternative Preschools in ABC (CARE): `fABC' (`fCARE') Females; `mABC' (`mCARE') Males]");
#delimit cr
cd $output
graph export abccare_controlcontamination.eps, replace
