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
global datafam     = "$klmmexico/abccare/health_plots/"
global datapsid    = "$klmshare/Data_Central/data-repos/psid/extensions/abc-match/"
// output
global output      = "$projects/abc-treatmenteffects-finalseason/output/"

// bring weights from psid file
cd $datapsid
use psid-abc-match.dta, clear
keep id wtabc_allids
tempfile weights 
save "`weights'", replace

// bring gender from data file for psid inter/extrapolation
cd $output 
use psid_interextra.dta, clear 
tempfile psids
save "`psids'", replace

cd $datafam
use psid_qaly_imputed_abcsel.dta, clear
merge 1:1 id year using "`psids'"
keep if _merge == 3
drop _merge

merge m:1 id using "`weights'"
keep if _merge != 2
drop _merge

keep if black == 1 & eduever < 12
keep if age >=27 & age <=80
replace qaly = qaly*150

collapse (mean) qaly (semean) seqaly=qaly [aw=wtabc_allids], by(age male)
cd $output

gen qalymin = qaly - seqaly
gen qalymax = qaly + seqaly

#delimit
twoway (lowess qaly    age if male == 0, lwidth(1.2)   lpattern(solid) lcolor(gs0))
       (lowess qalymax age if male == 0, lpattern(dash) lcolor(gs0))
       (lowess qalymin age if male == 0, lpattern(dash) lcolor(gs0))
	, 
		  legend(rows(1) order(1 2) label(1 "Mean") label(2 "+/- s.e.") size(small))
		  xlabel(30[5]65, grid glcolor(gs14)) ylabel(80[10]140, angle(h) glcolor(gs14))
		  xtitle(Age) ytitle("QALYs (1000s 2014 USD)")
		  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr 
graph export psidqaly_s0.eps, replace

#delimit
twoway (lowess qaly    age if male == 1, lwidth(1.2)   lpattern(solid) lcolor(gs0) bwidth(.7))
       (lowess qalymax age if male == 1, lpattern(dash) lcolor(gs0) bwidth(.7))
       (lowess qalymin age if male == 1, lpattern(dash) lcolor(gs0) bwidth(.7) )
	, 
		  legend(rows(1) order(1 2) label(1 "Mean") label(2 "+/- s.e.") size(small))
		  xlabel(30[5]65, grid glcolor(gs14)) ylabel(80[10]140, angle(h) glcolor(gs14))
		  xtitle(Age) ytitle("QALYs (1000s 2014 USD)")
		  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr 
graph export psidqaly_s1.eps, replace
