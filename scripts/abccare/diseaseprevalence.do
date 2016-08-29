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
use  health_projections_combined0731.dta,  clear
// aorder
// save, replace 

replace mcrep = 0 if mcrep == .
drop if (bsrep == 0) & (mcrep > 1)
keep if bsrep == 0 & mcrep == 1
sort id

// id's file
preserve
# delimit 
keep id;
# delimit cr
tempfile ids
save   "`ids'", replace
restore

# delimit
global ToReshape cancre30-cancre79 diabe30-diabe79 hearte30-hearte79 
                 hibpe30-hibpe79 lunge30-lunge79 stroke30-stroke79 died30-died79;
# delimit cr

keep id $ToReshape 
reshape long cancre diabe hearte hibpe lunge stroke died, i(id) j(age)

tempfile health
save "`health'", replace

cd $dataabccare
use append-abccare_iv.dta, clear
keep id R male
tempfile IDMales
save "`IDMales'", replace

use "`health'", clear
merge m:1 id using "`IDMales'"
keep if _merge == 3
drop _merge

collapse (sum) cancre diabe hearte hibpe lunge stroke died, by(male R age)

foreach var of varlist diabe hibpe stroke {
	// replace `var' = 1 if `var' != . & (died == 1 | died == .)
	foreach sex of numlist 1 {
		#delimit
		twoway (lowess `var' age if R == 0 & male == `sex',  lwidth(vthick) lpattern(solid) lcolor(gs4))
		       (lowess `var' age if R == 1 & male == `sex',  lwidth(vthick) lpattern(dash)  lcolor(gs8))
			, 
				  legend(label(1 Control) label(2 Treatment))
				  xlabel(30[10]80, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
				  xtitle(Age) ytitle("")
				  graphregion(color(white)) plotregion(fcolor(white));
		#delimit cr
		graph export `var'_`sex'.eps, replace
		di in r "Enter after seeing Figure" _request(Hello)
		
	}
}

