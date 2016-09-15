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
global dataweights  = "$klmmexico/abccare/as_weights/weights_09122016"
// output
global output      = "$projects/abc-treatmenteffects-finalseason/output/"

// bring weights from psid file
cd $datapsidw
use psid-abc-match.dta, clear

keep id wtabc_allids p_inc0y m_ed0y
tempfile dandweights 
save "`dandweights'", replace

cd $datapsid
use psid-base.dta, clear

merge m:1 id using "`dandweights'"
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

tempfile psidwide 
save   "`psidwide'", replace

foreach sex of numlist 0 1 {
	matrix all`sex' = J(1,2,.)
	matrix colnames all`sex' = m`sex' se`sex'
	foreach num of numlist 25(1)65 {
		
		// B \in B_{0}
		replace inc_labor`num' = inc_labor`num'/1000 if male == `sex' & black == 1 & m_ed0y <= 12
		summ inc_labor`num' if male == `sex' & black == 1 & m_ed0y <= 12
		local m`num'`sex'  = r(mean)
		local sd`num'`sex' = r(sd)
		local n`num'`sex'  = r(N)
		local se`num'`sex' = (`m`num'`sex'')/(`sd`num'`sex''/(sqrt(`n`num'`sex'')))
		matrix stats`num'`sex' = [`m`num'`sex'',`se`num'`sex'']
		matrix colnames stats`num'`sex' =  m`sex' se`sex'

		mat_rapp all`sex' : all`sex' stats`num'`sex'
	}
	matrix all`sex' = all`sex'[2...,1...]
}
matrix all = [all1,all0]

cd $dataweights
use psid-weights-finaldata.dta, clear
merge m:1 id using  "`psidwide'" 
keep if _merge == 3

foreach sex of numlist 0 1 {
	matrix allw`sex' = J(1,2,.)
	matrix colnames allw`sex' = mw`sex' sdw`sex'
		foreach num of numlist 25(1)65 {
			replace inc_labor`num' = inc_labor`num'/1000 if male == `sex'
			matrix allw`sex'`num' = J(1,1,.)
			matrix colnames allw`sex'`num' = mw`sex'
			foreach draw of numlist 0(1)98 {
				summ inc_labor`num' if male == `sex' & draw == `draw' [aw=wtabc_allids_c3_control], meanonly
				local m`num'`draw'`sex'  = r(mean)
				matrix stats`num'`draw'`sex' = [`m`num'`draw'`sex'']
				matrix colnames stats`num'`draw'`sex' = mw`sex'
				
				mat_rapp allw`sex'`num' : allw`sex'`num' stats`num'`draw'`sex'
			}
			matrix allw`sex'`num' = allw`sex'`num'[2...,1...]
			preserve
			clear
			svmat allw`sex'`num', names(col)
			summ mw`sex'
			local mean   = r(mean)
			local sd     = r(sd)
			local  N     = r(N)
			local semean = `mean'/(`sd'/sqrt(`N'))
			
			matrix stats`num'`sex' = [`mean',`semean']
			matrix colnames stats`num'`sex' = mw`sex' sdw`sex'
			
			mat_rapp allw`sex' : allw`sex' stats`num'`sex'
			restore
		}
	matrix allw`sex' = allw`sex'[2...,1...]
}
matrix allw = [allw1,allw0]
matrix allallw = [all,allw]

clear 
svmat allallw, names(col)
gen age = _n + 24
rename sdw1 sew1 
rename sdw0 sew0

foreach sex of numlist 0 1 {
	gen m`sex'max = m`sex' + se`sex' 
	gen m`sex'min = m`sex' - se`sex'
	
	gen mw`sex'max = mw`sex' + sew`sex' 
	gen mw`sex'min = mw`sex' - sew`sex'
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

cd $dataabcres
save allcontrolcomparisons.dta, replace


/*
cd $output
// B \in B0 vs. Control

#delimit
twoway (lowess mean_age1  age, lwidth(1.2) lpattern(solid) lcolor(gs0)  bwidth(.3))
       (lowess m1        age, lwidth(1.2) lpattern(solid) lcolor(gs8)  bwidth(.3))
       
       (lowess plus1 age,  lpattern(dash) lcolor(gs0) bwidth(.3))
       (lowess minus1 age,  lpattern(dash) lcolor(gs0) bwidth(.3))
       
       (lowess m1max age,  lpattern(dash) lcolor(gs8) bwidth(.3))
       (lowess m1min age,  lpattern(dash) lcolor(gs8) bwidth(.3))
       
        , 
		  legend(rows(1) order(1 2 3) label(1 "PSID, Disadvantaged") label(2 "PSID, Control-group Matches") label(3 "+/- s.e.") size(small))
		  xlabel(25[5]65, grid glcolor(gs14)) ylabel(10[10]50, angle(h) glcolor(gs14))
		  xtitle(Age) ytitle("Labor Income (1000s 2014 USD)")
		  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr
graph export psid_B0_control_s1.eps, replace

/*
// B \in B0 vs Matching
#delimit
twoway (lowess m1           age, lwidth(1.2) lpattern(solid) lcolor(gs0)  bwidth(.9))
       (lowess mw1    age, lwidth(1.2) lpattern(solid) lcolor(gs8)  bwidth(.9))
       
       (lowess m1max age,  lpattern(dash) lcolor(gs0) bwidth(.9))
       (lowess m1min age,  lpattern(dash) lcolor(gs0) bwidth(.9))
       
       (lowess mw1max age,  lpattern(dash) lcolor(gs8) bwidth(.9))
       (lowess mw1min age,  lpattern(dash) lcolor(gs8) bwidth(.9))
       
        , 
		  legend(rows(1) order(1 2 3) label(1 "PSID, Disadvantaged") label(2 "PSID, Control-group Matches") label(3 "+/- s.e.") size(small))
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
		  legend(rows(1) order(1 2 3) label(1 "PSID, Disadvantaged") label(2 "PSID, Control-group Matches") label(3 "+/- s.e.") size(small))
		  xlabel(25[5]65, grid glcolor(gs14)) ylabel(10[10]50, angle(h) glcolor(gs14))
		  xtitle(Age) ytitle("Labor Income (1000s 2014 USD)")
		  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr
graph export psid_B0_match_s0.eps, replace

// psid disadvantaged only
#delimit
twoway (lowess m1           age, lwidth(1.2) lpattern(solid) lcolor(gs0)  bwidth(.25))
       (lowess m1max age,  lpattern(dash) lcolor(gs0) bwidth(.25))
       (lowess m1min age,  lpattern(dash) lcolor(gs0) bwidth(.25))
       
        , 
		  legend(rows(1) order(1 2) label(1 "PSID, Disadvantaged") label(2 "+/- s.e.") size(small))
		  xlabel(25[5]65, grid glcolor(gs14)) ylabel(0[20]80, angle(h) glcolor(gs14))
		  xtitle(Age) ytitle("Labor Income (1000s 2014 USD)")
		  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr
graph export psid_disad_s1.eps, replace

#delimit
twoway (lowess m0           age, lwidth(1.2) lpattern(solid) lcolor(gs0)  bwidth(.25))
       (lowess m0max age,  lpattern(dash) lcolor(gs0) bwidth(.25))
       (lowess m0min age,  lpattern(dash) lcolor(gs0) bwidth(.25))
       
        , 
		  legend(rows(1) order(1 2) label(1 "PSID, Disadvantaged") label(2 "+/- s.e.") size(small))
		  xlabel(25[5]65, grid glcolor(gs14)) ylabel(0[10]50, angle(h) glcolor(gs14))
		  xtitle(Age) ytitle("Labor Income (1000s 2014 USD)")
		  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr
graph export psid_disad_s0.eps, replace
