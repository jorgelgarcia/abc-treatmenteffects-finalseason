version 12.0
set more off
clear all
set matsize 11000
set maxvar  32000

/*
Project :       ABC, CARE Predicted QALYs and Total Medical Costs
Description:    
*This version:  July 22, 2016
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
global scripts     = "$projects/abc-treatmenteffects-finalseason/scripts/"
// ready data
global datafam     = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/fam-merge/mergefiles/"
global dataabccare = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
// output
global output      = "$projects/abc-treatmenteffects-finalseason/output/"

cd $datafam
use health_projections_0720.dta, clear

// keep private and public costs
keep if bsrep == 0 & mcrep == 1
keep id died*
drop *_surv*
tempfile all
save "`all'", replace

// call the female/male and treatment indicators
cd $dataabccare
use append-abccare_iv.dta, clear
keep id R male
tempfile IDMales
save "`IDMales'", replace

use "`all'", clear
merge m:1 id using "`IDMales'"
keep if _merge == 3
drop _merge

// to long 
reshape long died, i(id) j(age)
drop if age <= 30 | age > 79
gen agedied = age if died == 1
bysort id : egen agedied2 = max(agedied)
drop agedied
rename agedied2 agedied
replace died = 1 if agedied <= age & age != . & agedied != .
replace died = 0 if died == .

collapse (mean) died, by(age R male)
replace died = 1 - died

cd $output
keep if age >= 30
foreach sex of numlist 0 1 {
	#delimit
	twoway (lowess died age if R == 0 & male == `sex', msymbol(square)  mfcolor (gs0) mlcolor(gs0) msize(large) connect(l) lwidth(vthick) lpattern(solid) lcolor(gs4))
	       (lowess died age if R == 1 & male == `sex', msymbol(circle)  mfcolor (gs5) mlcolor(gs5) msize(large) connect(l) lwidth(vthick) lpattern(dash)  lcolor(gs8))
		, 
			  legend(label(1 Control) label(2 Treatment))
			  xlabel(30[10]80, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
			  xtitle(Age) ytitle("")
			  graphregion(color(white)) plotregion(fcolor(white));
	#delimit cr 
	graph export diedlcycle_s`sex'.eps, replace
}
