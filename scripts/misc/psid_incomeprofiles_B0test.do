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
global datapsid     = "$klmshare/Data_Central/data-repos/psid/base/"
global datapsidw    = "$klmshare/Data_Central/data-repos/psid/extensions/abc-match/"
global datanlsy     = "$klmmexico/BPSeason2/"
global dataabccare  = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
global dataabcres   = "$klmmexico/abccare/income_projections"
// output
global output      = "$projects/abc-treatmenteffects-finalseason/output/"

// bring weights from psid file
cd $datapsidw
use psid-abc-match.dta, clear
keep id wtabc_allids p_inc0y m_ed0y
tempfile weights 
save "`weights'", replace

cd $datapsid
use psid-base.dta, clear

merge m:1 id using "`weights'"
keep if _merge != 2
drop _merge

keep id male black birthyear race age* edu bmi* inc_labor* lweight* wtabc_allids p_inc0y m_ed0y
rename edu eduever

reshape long age inc_labor lweight, i(id) j(year)
drop if birthyear == .
bysort id: egen edueverbest = mean(eduever)
drop eduever
rename  edueverbest eduever
drop if eduever == .
keep if year >= 1997 & year <= 2011

// generate id's file for USC
preserve
keep id year male eduever black wtabc_allids p_inc0y m_ed0y
cd $output
saveold psid_interextra.dta, replace
restore

keep id male age inc_labor birthyear year lweight black eduever wtabc_allids p_inc0y m_ed0y
bysort id : egen birthyear2 = mean(birthyear)
gen age2 = year - birthyear2
drop if age2 < 0

keep id age2 inc_labor male inc_labor lweight black eduever wtabc_allids p_inc0y m_ed0y
reshape wide inc_labor lweight, i(id) j(age2)
keep id male inc_labor25-inc_labor65 lweight25-lweight65 black eduever wtabc_allids p_inc0y m_ed0y
replace m_ed0y = eduever if m_ed0y ==.

foreach sex of numlist 0 1 {
	matrix all`sex' = J(1,6,.)
	matrix colnames all`sex' = m`sex' sd`sex' n`sex' mw`sex' sdw`sex' nw`sex'
	foreach num of numlist 25(1)65 {
		
		// B \in B_{0}
		summ inc_labor`num' if male == `sex' & black == 1 & m_ed0y <= 12
		local m`num'`sex'  = r(mean)
		local sd`num'`sex' = r(sd)
		local n`num'`sex'  = r(N)
		matrix stats`num'`sex' = [`m`num'`sex'',`sd`num'`sex'',`n`num'`sex'']
		matrix colnames stats`num'`sex' =  m`sex' sd`sex' n`sex'
		
		// weighted
		summ inc_labor`num' [iw=wtabc_allids] if male == `sex' & black == 1 & m_ed0y <= 16
		local mw`num'`sex'  = r(mean)
		local sdw`num'`sex' = r(sd)
		local nw`num'`sex'  = r(N)
		matrix statsw`num'`sex' = [`mw`num'`sex'',`sdw`num'`sex'',`nw`num'`sex'']
		matrix colnames statsw`num'`sex' =  mw`sex' sdw`sex' nw`sex'
		
		matrix stats`num'`sex' = [stats`num'`sex',statsw`num'`sex']
		mat_rapp all`sex' : all`sex' stats`num'`sex'
	}
	matrix all`sex' = all`sex'[2...,1...]
}
matrix all = [all1,all0]

clear 
svmat all, names(col)
gen age = _n + 24

foreach sex of numlist 0 1 {
	gen se`sex'  = sd`sex'/sqrt(n`sex')
	gen sew`sex' = sdw`sex'/sqrt(nw`sex')
}

foreach sex of numlist 0 1 {
	gen m`sex'max = m`sex' + se`sex' 
	gen m`sex'min = m`sex' - se`sex'
	
	gen mw`sex'max = mw`sex' + sew`sex' 
	gen mw`sex'min = mw`sex' - sew`sex'
}

foreach var of varlist m1* m0* mw* {
	replace `var' = `var'/1000
}

tempfile psid
save   "`psid'", replace

// get control group data
cd $dataabcres
use labor_income_collapsed.dta, clear
keep if age >= 25 & age <= 65
keep if R == 0
keep age mean_age plus minus male

foreach num of numlist 0 1 {
preserve
keep if male == `num'
drop male

	foreach var of varlist  mean_age plus minus {
		rename `var' `var'`num'
	}

tempfile exp`num'
save "`exp`num''", replace

use "`psid'"
merge 1:1 age using "`exp`num''"
keep if _merge == 3
drop _merge

save "`psid'", replace

restore
}
use "`psid'", clear

cd $output
// B \in B0 vs Matching
#delimit
twoway (lowess m1           age, lwidth(1.2) lpattern(solid) lcolor(gs0)  bwidth(.25))
       (lowess mw1    age, lwidth(1.2) lpattern(solid) lcolor(gs8)  bwidth(.25))
       
       (lowess m1max age,  lpattern(dash) lcolor(gs0) bwidth(.25))
       (lowess m1min age,  lpattern(dash) lcolor(gs0) bwidth(.25))
       
       (lowess mw1max age,  lpattern(dash) lcolor(gs8) bwidth(.25))
       (lowess mw1min age,  lpattern(dash) lcolor(gs8) bwidth(.25))
       
        , 
		  legend(rows(1) order(1 2 3) label(1 "PSID, Disadvantaged") label(2 "PSID, Matched to Control Group") label(3 "+/- s.e.") size(small))
		  xlabel(25[5]65, grid glcolor(gs14)) ylabel(10[10]50, angle(h) glcolor(gs14))
		  xtitle(Age) ytitle("Labor Income (1000s 2014 USD)")
		  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr
graph export psid_B0_match_s1.eps, replace

#delimit
twoway (lowess m0           age, lwidth(1.2) lpattern(solid) lcolor(gs0)  bwidth(.25))
       (lowess mw0    age, lwidth(1.2) lpattern(solid) lcolor(gs8)  bwidth(.25))
       
       (lowess m0max age,  lpattern(dash) lcolor(gs0) bwidth(.25))
       (lowess m0min age,  lpattern(dash) lcolor(gs0) bwidth(.25))
       
       (lowess mw0max age,  lpattern(dash) lcolor(gs8) bwidth(.25))
       (lowess mw0min age, lpattern(dash) lcolor(gs8) bwidth(.25))
       
        , 
		  legend(rows(1) order(1 2 3) label(1 "PSID, Disadvantaged") label(2 "PSID, Matched to Control Group") label(3 "+/- s.e.") size(small))
		  xlabel(25[5]65, grid glcolor(gs14)) ylabel(10[10]50, angle(h) glcolor(gs14))
		  xtitle(Age) ytitle("Labor Income (1000s 2014 USD)")
		  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr
graph export psid_B0_match_s0.eps, replace

// Control group vs. Control Matched
#delimit
twoway (lowess mean_age1           age, lwidth(1.2) lpattern(solid) lcolor(gs0)  bwidth(.25))
       (lowess mw1    age, lwidth(1.2) lpattern(solid) lcolor(gs8)  bwidth(.25))
       
       (lowess plus1  age,  lpattern(dash) lcolor(gs0) bwidth(.25))
       (lowess minus1 age,  lpattern(dash) lcolor(gs0) bwidth(.25))
       
       (lowess mw1max age,  lpattern(dash) lcolor(gs8) bwidth(.25))
       (lowess mw1min age, lpattern(dash) lcolor(gs8) bwidth(.25))
       
        , 
		  legend(rows(1) order(1 2 3) label(1 "ABC/CARE Control") label(2 "PSID, Matched to Control Group") label(3 "+/- s.e.") size(small))
		  xlabel(25[5]65, grid glcolor(gs14)) ylabel(10[10]50, angle(h) glcolor(gs14))
		  xtitle(Age) ytitle("Labor Income (1000s 2014 USD)")
		  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr
graph export psid_control_match_s1.eps, replace

#delimit
twoway (lowess mean_age0           age, lwidth(1.2) lpattern(solid) lcolor(gs0)  bwidth(.25))
       (lowess mw0    age, lwidth(1.2) lpattern(solid) lcolor(gs8)  bwidth(.25))
       
       (lowess plus0  age,  lpattern(dash) lcolor(gs0) bwidth(.25))
       (lowess minus0 age,  lpattern(dash) lcolor(gs0) bwidth(.25))
       
       (lowess mw1max age,  lpattern(dash) lcolor(gs8) bwidth(.7))
       (lowess mw1min age, lpattern(dash) lcolor(gs8) bwidth(.7))
       
        , 
		  legend(rows(1) order(1 2 3) label(1 "ABC/CARE Control") label(2 "PSID, Matched to Control Group") label(3 "+/- s.e.") size(small))
		  xlabel(25[5]65, grid glcolor(gs14)) ylabel(10[10]50, angle(h) glcolor(gs14))
		  xtitle(Age) ytitle("Labor Income (1000s 2014 USD)")
		  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr
graph export psid_control_match_s0.eps, replace

// control matched only
#delimit
twoway (lowess m1           age, lwidth(1.2) lpattern(solid) lcolor(gs0)  bwidth(.25))
       (lowess m1max age,  lpattern(dash) lcolor(gs0) bwidth(.25))
       (lowess m1min age,  lpattern(dash) lcolor(gs0) bwidth(.25))
       
        , 
		  legend(rows(1) order(1 2) label(2 "PSID, Matched to Control Group") label(2 "+/- s.e.") size(small))
		  xlabel(25[5]65, grid glcolor(gs14)) ylabel(10[10]80, angle(h) glcolor(gs14))
		  xtitle(Age) ytitle("Labor Income (1000s 2014 USD)")
		  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr
graph export psid_match_s1.eps, replace

#delimit
twoway (lowess m0           age, lwidth(1.2) lpattern(solid) lcolor(gs0)  bwidth(.25))
       (lowess m0max age,  lpattern(dash) lcolor(gs0) bwidth(.25))
       (lowess m0min age,  lpattern(dash) lcolor(gs0) bwidth(.25))
       
        , 
		  legend(rows(1) order(1 2) label(2 "PSID, Matched to Control Group") label(2 "+/- s.e.") size(small))
		  xlabel(25[5]65, grid glcolor(gs14)) ylabel(0[10]50, angle(h) glcolor(gs14))
		  xtitle(Age) ytitle("Labor Income (1000s 2014 USD)")
		  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr
graph export psid_match_s0.eps, replace