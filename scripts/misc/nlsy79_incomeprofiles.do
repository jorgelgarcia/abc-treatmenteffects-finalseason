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
global datapsid    = "$klmshare/Data_Central/data-repos/psid/base/"
global datanlsy    = "$klmmexico/BPSeason2/"
global dataabccare = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
// output
global output      = "$projects/abc-treatmenteffects-finalseason/output/"

// open NLSY79
cd $datapsid
use psid-base.dta, clear
keep id male  birthyear race age* edu inc_labor*
rename edu eduever

reshape long age inc_labor, i(id) j(year)
drop if birthyear == .
bysort id: egen edueverbest = mean(eduever)
drop eduever
rename  edueverbest eduever
drop if eduever == .
keep if eduever <= 12 & age !=.

keep id male age inc_labor birthyear year
bysort id : egen birthyear2 = mean(birthyear)
gen age2 = year - birthyear2
drop if age2 < 0

keep id age2 inc_labor male inc_labor
reshape wide inc_labor, i(id) j(age2)
keep id male inc_labor25-inc_labor60

collapse (median) inc_labor*, by(male)

drop male
mkmat *, matrix(allvars)
matrix rownames allvars = fm mm
matrix allvars = allvars'
clear
svmat allvars, names(col)
gen age = _n + 23

foreach var of varlist fm mm {
	replace `var' = `var'/1000
}
cd $output
#delimit
twoway (line fm age, lwidth(thick) lpattern(solid) lcolor(gs0))
        , 
		  xlabel(25[5]60, grid glcolor(gs14)) ylabel(5[5]25, angle(h) glcolor(gs14))
		  xtitle(Age) ytitle("Income (1000s 2014 USD)")
		  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr 
graph export psid_incomeprofiles_s0.eps, replace

#delimit
twoway (line mm age, lwidth(thick) lpattern(solid) lcolor(gs0))
        , 
		  xlabel(25[5]60, grid glcolor(gs14)) ylabel(20[10]70, angle(h) glcolor(gs14))
		  xtitle(Age) ytitle("Income (1000s 2014 USD)")
		  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr 
graph export psid_incomeprofiles_s1.eps, replace

