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

// open data
cd $dataabccare
use append-abccare_iv.dta, clear

// replace dc_mo_pre = 0 if dc_mo_pre == 2
sort    Q
replace Q = Q/60
cumul   Q if program=="abc" & treat == 0, gen(cdf_Q) 
summ    P if program=="abc" & treat == 0
// replace dc_mo_pre = 52 if dc_mo_pre >= 52

#delimit
twoway (line cdf_Q Q if program=="abc" & treat == 0, lwidth(vthick) lcolor(gs0))
      , 
		  xlabel(, grid glcolor(gs14)) ylabel(0[.1]1, angle(h) glcolor(gs14))
		  xtitle(Proportion of Months in Preschool from Ages 0 to 5) ytitle(Cumulative Density Function)
		  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr
cd $output
graph export abc_controlcontamination_months.eps, replace
