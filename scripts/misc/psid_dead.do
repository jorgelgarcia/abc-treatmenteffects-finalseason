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
use psid_died_abcsel.dta, clear
merge 1:1 id year using "`psids'"
keep if _merge == 3
drop _merge

merge m:1 id using "`weights'"
keep if _merge != 2
drop _merge

// keep if source == "psid"
// keep if black == 1 & eduever < 12
keep if age >=30 & age <=80

/*
replace died = 1 - died
collapse (mean) died (semean) sedied=died, by(age male)
cd $output

gen diedmin = died - sedied
gen diedmax = died + sedied

/*
#delimit
twoway (lowess died    age if male == 0, lwidth(1.2)   lpattern(solid) lcolor(gs0))
       (lowess diedmax age if male == 0, lpattern(dash) lcolor(gs0))
       (lowess diedmin age if male == 0, lpattern(dash) lcolor(gs0))
	, 
		  legend(rows(1) order(1 2) label(1 "Mean") label(2 "+/- s.e.") size(small))
		  xlabel(30[5]80, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
		  xtitle(Age) ytitle("Probability of Being Alive")
		  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr 
graph export psiddied_s0.eps, replace

#delimit
twoway (lowess died    age if male == 1, lwidth(1.2)   lpattern(solid) lcolor(gs0) bwidth(.7))
       (lowess diedmax age if male == 1, lpattern(dash) lcolor(gs0) bwidth(.7))
       (lowess diedmin age if male == 1, lpattern(dash) lcolor(gs0) bwidth(.7) )
	, 
		  legend(rows(1) order(1 2) label(1 "Mean") label(2 "+/- s.e.") size(small))
		  xlabel(30[5]80, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
		  xtitle(Age) ytitle("Probability of Being Alive"")
		  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr 
graph export psiddied_s1.eps, replace
