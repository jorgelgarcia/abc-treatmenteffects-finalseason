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
keep id male birthyear race age* edu inc_labor* lweight*
rename edu eduever

reshape long age inc_labor lweight, i(id) j(year)
drop if birthyear == .
bysort id: egen edueverbest = mean(eduever)
drop eduever
rename  edueverbest eduever
drop if eduever == .
keep if eduever <= 12 & age !=.
keep if year >= 1997 & year <= 2011

keep id male age inc_labor birthyear year lweight
bysort id : egen birthyear2 = mean(birthyear)
gen age2 = year - birthyear2
drop if age2 < 0

keep id age2 inc_labor male inc_labor lweight
reshape wide inc_labor lweight, i(id) j(age2)
keep id male inc_labor25-inc_labor65 lweight25-lweight65

foreach sex of numlist 0 1 {
	matrix all`sex' = J(1,3,.)
	matrix colnames all`sex' = m`sex' sd`sex' n`sex'
	foreach num of numlist 25(1)65 {
		// replace inc_labor`num' = inc_labor`num'/1000
		summ inc_labor`num' [iw = lweight`num'] if male == `sex'
		local m`num'`sex'  = r(mean)
		local sd`num'`sex' = r(sd)
		local n`num'`sex'  = r(N)
		
		matrix stats`num'`sex' = [`m`num'`sex'',`sd`num'`sex'',`n`num'`sex'']
		matrix colnames stats`num'`sex' =  m`sex' sd`sex' n`sex'
		
		mat_rapp all`sex' : all`sex' stats`num'`sex'
	}
	matrix all`sex' = all`sex'[2...,1...]
}
matrix all = [all1,all0]

clear 
svmat all, names(col)
gen age = _n + 24

foreach sex of numlist 0 1 {
	gen se`sex' = sd`sex'/sqrt(n`sex')
}

foreach sex of numlist 0 1 {
	gen m`sex'max = m`sex' + se`sex' 
	gen m`sex'min = m`sex' - se`sex'
}

foreach var of varlist m1 m0 m0max m0min m1max m1min {
	replace `var' = `var'/1000
}

cd $output

#delimit
twoway (lowess m1    age, lwidth(1.2) lpattern(solid) lcolor(gs0)  bwidth(.25))
       (lowess m1max age, lwidth(thick) lpattern(dash) lcolor(gs0) bwidth(.25))
       (lowess m1min age, lwidth(thick) lpattern(dash) lcolor(gs0) bwidth(.25))
        , 
		  legend(rows(1) order(1 2) label(1 "Mean") label(2 "+/- s.e.") size(small))
		  xlabel(25[5]65, grid glcolor(gs14)) ylabel(20[10]70, angle(h) glcolor(gs14))
		  xtitle(Age) ytitle("Labor Income (1000s 2014 USD)")
		  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr 
graph export psid_incomeprofiles_s1.eps, replace

#delimit
twoway (lowess m0    age, lwidth(1.2) lpattern(solid) lcolor(gs0)  bwidth(.35))
       (lowess m0max age, lwidth(thick) lpattern(dash) lcolor(gs0) bwidth(.35))
       (lowess m0min age, lwidth(thick) lpattern(dash) lcolor(gs0) bwidth(.35))
        , 
		  legend(rows(1) order(1 2) label(1 "Mean") label(2 "+/- s.e.") size(small))
		  xlabel(25[5]65, grid glcolor(gs14)) ylabel(15[5]40, angle(h) glcolor(gs14))
		  xtitle(Age) ytitle("Labor Income (1000s 2014 USD)")
		  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr 
graph export psid_incomeprofiles_s0.eps, replace

