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
use health_projections_ipolated_0915.dta, clear
// aorder 
// save, replace

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
keep if bsrep == 0 & mcrep == 1
reshape long prvmd pubmd qaly, i(num_id) j(age)
replace qaly = qaly*150
egen md = rowtotal(prvmd pubmd), missing 
collapse (mean) md prvmd pubmd qaly (semean) seqaly=qaly semd=md seprvmd=prvmd sepubmd=pubmd, by(age R male)

cd $output
keep if age >=30 & age <=65
foreach sex of numlist 0 {
	foreach var of varlist qaly {
		gen `var'min = `var' - se`var'
		gen `var'max = `var' + se`var'
		#delimit
		twoway (lowess `var'    age if R == 0 & male == `sex', lwidth(1.2)   lpattern(solid) lcolor(gs0) )
		       (lowess `var'    age if R == 1 & male == `sex', lwidth(1.2)   lpattern(solid) lcolor(gs9))
		       (lowess `var'min age if R == 1 & male == `sex', lpattern(dash) lcolor(gs9) )
		       (lowess `var'max age if R == 1 & male == `sex', lpattern(dash) lcolor(gs9) )
		       (lowess `var'min age if R == 0 & male == `sex', lpattern(dash) lcolor(gs0) )
		       (lowess `var'max age if R == 0 & male == `sex', lpattern(dash) lcolor(gs0) )
			, 
				  legend(rows(1) order(2 1 5) label(1 "Control") label(2 "Treatment") label(5 "+/- s.e.") size(small))
				  xlabel(30[5]65, grid glcolor(gs14)) ylabel(80[10]140, angle(h) glcolor(gs14))
				  xtitle(Age) ytitle("QALYs (1000s 2014 USD)")
				  graphregion(color(white)) plotregion(fcolor(white));
		#delimit cr 
		graph export `var'lcycle_s`sex'.eps, replace
		drop *min *max
	}
}
