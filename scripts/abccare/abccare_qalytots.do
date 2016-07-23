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
use health_projections_ipolated_0721.dta, clear

// keep private and public costs
keep num_id id mcrep bsrep prvmd* pubmd* qaly*
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
drop if bsrep == 0 & mcrep == 0
reshape long prvmd pubmd qaly, i(num_id) j(age)
egen md = rowtotal(prvmd pubmd), missing 
collapse (mean) md qaly, by(age R male)

cd $output
keep if age >= 30
foreach sex of numlist 0 1 {
	foreach var of varlist md qaly {
		#delimit
		twoway (scatter `var' age if R == 0 & male == `sex', msymbol(square)  mfcolor (gs0) mlcolor(gs0) msize(large) /*connect(l) lwidth(medthick) lpattern(solid) lcolor(gs4)*/)
		       (scatter `var' age if R == 1 & male == `sex', msymbol(circle)  mfcolor (gs5) mlcolor(gs5) msize(large) /*connect(l) lwidth(medthick) lpattern(dash)  lcolor(gs8)*/)
			, 
				  legend(label(1 Control) label(2 Treatment))
				  xlabel(30[10]80, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
				  xtitle(Age) ytitle("")
				  graphregion(color(white)) plotregion(fcolor(white));
		#delimit cr 
		graph export `var'lcycle_s`sex'.eps, replace
	}
}
