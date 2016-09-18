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
global scripts      = "$projects/abc-treatmenteffects-finalseason/scripts/"
// ready data
global collapseprj  = "$klmmexico/abccare/income_projections/"
global dataabccare  = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
global datacnlsyw   = "$klmshare/Data_Central/data-repos/nlsy/extensions/abc-match-cnlsy/"
global datanlsyw    = "$klmshare/Data_Central/data-repos/nlsy/extensions/abc-match-nlsy/"
global datacnlsyp   = "$klmshare/Data_Central/data-repos/nlsy/primary/cnlsy/base"
global datapsidw    = "$klmshare/Data_Central/data-repos/psid/extensions/abc-match/"
global weights      = "$klmmexico/abccare/as_weights"
// output
global output       = "$projects/abc-treatmenteffects-finalseason/output/"

// ABC/CARE
// predicted at age 30
cd $collapseprj
use  labor_income_collapsed_pset1_mset3.dta, clear
keep age R mean_age semean_age plus minus male

foreach num of numlist 0 1 {
	preserve
	keep if R == `num'
	foreach var of varlist mean_age semean_age plus minus {
		rename `var' `var'`num'
	}
	drop R
	tempfile abc`num'
	save "`abc`num''", replace
	restore
}

// CNLSY
// get weights
cd $weights 
use cnlsy-weights-finaldata.dta, clear
keep if draw == 0
drop draw
tempfile weights
save "`weights'", replace

// disadvantaged
cd $datacnlsyw 
use  cnlsy-abc-match.dta, clear
summ    si30y_inc_labor
replace si30y_inc_labor = si30y_inc_labor/1000
drop if black != 1 | m_ed0y > 12
keep id male inc_labor20-inc_labor30
reshape long inc_labor, i(id) j(age)
tempfile cnlsydisad
save   "`cnlsydisad'", replace
merge m:1 id using "`weights'"
keep if _merge == 3
drop _merge

drop if inc_labor > 300000
replace inc_labor = inc_labor/1000
collapse (mean) mdisadcnlsy = inc_labor (semean) sedisadcnlsy = inc_labor, by(age male)
gen plusdisadcnlsy  = mdisadcnlsy + sedisadcnlsy
gen minusdisadcnlsy = mdisadcnlsy - sedisadcnlsy
save   "`cnlsydisad'", replace

// control/treatment
foreach group in control treat {
cd $datacnlsyw 
use  cnlsy-abc-match.dta, clear
summ    si30y_inc_labor
replace si30y_inc_labor = si30y_inc_labor/1000
keep id male inc_labor20-inc_labor30
reshape long inc_labor, i(id) j(age)
tempfile cnlsy`group'
save   "`cnlsy`group''", replace
merge m:1 id using "`weights'"
keep if _merge == 3
drop _merge

drop if inc_labor > 300000
replace inc_labor = inc_labor/1000
collapse (mean) m`group'cnlsy = inc_labor (semean) se`group'cnlsy = inc_labor [aw=wtabc_allids_c3_`group'], by(age male)
gen  plus`group'cnlsy = m`group'cnlsy + se`group'cnlsy
gen minus`group'cnlsy = m`group'cnlsy - se`group'cnlsy
save   "`cnlsy`group''", replace
}

// PSID
// get weights
cd $weights 
use psid-weights-finaldata.dta, clear
keep if draw == 0
drop draw
tempfile weights
save "`weights'", replace

// disadvantaged
cd $datapsidw 
use  psid-abc-match.dta, clear
summ    si30y_inc_labor
replace si30y_inc_labor = si30y_inc_labor/1000
// replace m_ed0y = years_30y if m_ed0y ==.
drop if black != 1 | m_ed0y > 12
keep id male inc_labor31-inc_labor44
reshape long inc_labor, i(id) j(age)
tempfile psiddisad
save   "`psiddisad'", replace
merge m:1 id using "`weights'"
keep if _merge == 3
drop _merge

drop if inc_labor > 300000
replace inc_labor = inc_labor/1000
collapse (mean) mdisadpsid = inc_labor (semean) sedisadpsid = inc_labor, by(age male)
gen plusdisadpsid  = mdisadpsid + sedisadpsid
gen minusdisadpsid = mdisadpsid - sedisadpsid
save   "`psiddisad'", replace

// disadvantaged
cd $datapsidw 
use  psid-abc-match.dta, clear
// replace m_ed0y = years_30y if m_ed0y ==.
drop if black != 1 | p_inc0y > 33000
keep id male inc_labor45-inc_labor65
reshape long inc_labor, i(id) j(age)
tempfile psiddisadlate
save   "`psiddisadlate'", replace
merge m:1 id using "`weights'"
keep if _merge == 3
drop _merge

drop if inc_labor > 300000
replace inc_labor = inc_labor/1000
collapse (mean) mdisadpsidlate = inc_labor (semean) sedisadpsidlate = inc_labor, by(age male)
gen plusdisadpsidlate  = mdisadpsidlate + sedisadpsidlate
gen minusdisadpsidlate = mdisadpsidlate - sedisadpsidlate
save   "`psiddisadlate'", replace

// control/treatment
foreach group in control treat {
cd $datapsidw 
use  psid-abc-match.dta, clear
summ    si30y_inc_labor
replace si30y_inc_labor = si30y_inc_labor/1000

foreach age of numlist 56(1)65 {
	summ inc_labor`age', d
	replace inc_labor`age' = . if inc_labor`age' > r(p90)
}

keep id black male inc_labor31-inc_labor65
reshape long inc_labor, i(id) j(age)
tempfile psid`group'
save   "`psid`group''", replace
merge m:1 id using "`weights'"
keep if _merge == 3
drop _merge

drop if inc_labor > 300000 | black == 1
replace inc_labor = inc_labor/1000

collapse (mean) m`group'psid = inc_labor (semean) se`group'psid = inc_labor [aw=wtabc_allids_c3_`group'], by(age male)
gen  plus`group'psid = m`group'psid + se`group'psid
gen minus`group'psid = m`group'psid - se`group'psid
save   "`psid`group''", replace
}

// NLSY
cd $weights 
use nlsy-weights-finaldata.dta, clear
keep if draw == 0
drop draw
tempfile weights
save "`weights'", replace

// control/treatment
foreach group in control treat {
cd $datanlsyw 
use  nlsy-abc-match.dta, clear
summ    si30y_inc_labor
replace si30y_inc_labor = si30y_inc_labor/1000
keep id black male inc_labor31-inc_labor55
reshape long inc_labor, i(id) j(age)
tempfile nlsy`group'
save   "`nlsy`group''", replace
merge m:1 id using "`weights'"
keep if _merge == 3
drop _merge

drop if inc_labor > 300000 | black == 1
replace inc_labor = inc_labor/1000
collapse (mean) m`group'nlsy = inc_labor (semean) se`group'nlsy = inc_labor [aw=wtabc_allids_c3_`group'], by(age male)
gen  plus`group'nlsy = m`group'nlsy + se`group'nlsy
gen minus`group'nlsy = m`group'nlsy - se`group'nlsy
save   "`nlsy`group''", replace
}

// 
clear
set obs 160
gen age = _n 
gen male = 0
replace male = 1 if age <= 80
replace age = age - 80 if age > 80

// merge all info
merge 1:1 age male using "`abc0'"
drop if _merge == 2
drop _merge
merge 1:1 age male using "`abc1'"
drop if _merge == 2
drop _merge

foreach group in control treat {
	foreach data in cnlsy psid nlsy {
		merge 1:1 age male using "``data'`group''"
		drop if _merge == 2
		drop _merge
	}
}

foreach data in cnlsy psid {
	merge 1:1 age male using "``data'disad'"
	drop if _merge == 2
	drop _merge
}
merge 1:1 age male using "`psiddisadlate'"
drop if _merge ==2
drop    _merge

// plots
cd $output
foreach var in m plus minus {
		egen `var'disad = rowtotal(`var'disadcnlsy `var'disadpsid `var'disadpsidlate), missing
}

foreach var in m plus minus {
	foreach group in treat control {
		gen     `var'`group' = . 
		replace `var'`group' = `var'`group'cnlsy if age <= 30
		replace `var'`group' = `var'`group'nlsy  if age >= 30 & age <= 55 & male == 1
		replace `var'`group' = `var'`group'psid  if age >= 30 & age <= 55 & male == 0
		replace `var'`group' = `var'`group'psid  if age >= 55
		
	}
}

merge 1:1 age male using realpredwide
drop if _merge == 2
drop _merge

gen realplus0  = real0 + realse0
gen realminus0 = real0 - realse0

gen predplus0  = pred0 + predse0
gen predminus0 = pred0 - predse0 

replace mcontrol     = pred0      if age == 30
replace pluscontrol  = predplus0  if age == 30
replace minuscontrol = predminus0 if age == 30

// at 21 real is predicted
replace mdisad        = real0     if age == 21
replace mcontrol     = real0      if age == 21
replace pluscontrol  = realplus0  if age == 21
replace minuscontrol = realminus0 if age == 21
replace plusdisad    = realplus0  if age == 21
replace minusdisad   = realminus0 if age == 21

gen sedisad   = plusdisad - mdisad
gen secontrol = pluscontrol - mcontrol

foreach stat in disad {
foreach num of numlist 0 1 {
	summ  m`stat'  if (age == 30  | age == 31) & male == `num'
	local  m`stat'30`num' = round(r(mean),.01)
	summ se`stat'  if (age == 30  | age == 31) & male == `num'
	local se`stat'30`num' = round(r(mean),.01)
}
}

foreach stat in control {
foreach num of numlist 0 1 {
	summ  m`stat'  if (age == 30  | age == 31) & male == `num'
	local  m`stat'30`num' = round(r(mean),.01)
	summ se`stat'  if (age == 30  | age == 31) & male == `num'
	local se`stat'30`num' = round(r(mean),.01)
}
}

keep if age >= 21
#delimit
twoway (lowess mdisad       age if male == 0 & age & age <= 44, lwidth(1.2) lpattern(solid) lcolor(gs8) bwidth(1))
       (lowess mcontrol     age if male == 0 & age & age <= 44, lwidth(1.2) lpattern(solid) lcolor(gs0) bwidth(.6))
       
       (lowess pluscontrol  age   if male == 0 & age <= 44 ,  lpattern(dash) lcolor(gs0) bwidth(.6))
       (lowess minuscontrol age   if male == 0 & age <= 44,  lpattern(dash) lcolor(gs0)  bwidth(.6))
       
       (lowess plusdisad  age if male == 0 & age <= 44,  lpattern(dash) lcolor(gs8))
       (lowess minusdisad age if male == 0 & age <= 44,  lpattern(dash) lcolor(gs8))
       
	(scatter real0  age                 if age == 30 & male == 0, mlcolor(black) mfcolor(white) msize(vlarge))
	(rcap    realplus0  realminus0 age  if age == 30 & male == 0, lcolor(black) lwidth(medthick))
       
        , 
        text( 30 32
         "ABC/CARE Eligible at t*: `mdisad300' (s.e. `sedisad300')"
	 " "
         "Synthetic Control Group at t*: `mcontrol300' (s.e. `secontrol300')"
         , size(small) place(nw) box just(left) margin(l+1 b+1 t+1 r+1) width(58) fcolor(none))
		  
		  
		  legend(rows(2) order(1 2 3 7 8) label(1 "ABC/CARE Eligible in PSID") label(2 "Synthetic Control Group-Matching Based") label(3 "+/- s.e.") 
		                              label(7 "Control Observed") label(8 "Observed +/- s.e.") size(vsmall))
		  xlabel(20 "20" 30 "Interpolation {&larr} t* {&rarr} Extrapolation" 40 "40", grid glcolor(gs14)) ylabel(10[10]50, angle(h) glcolor(gs14))
		  xtitle(Age) ytitle("Labor Income (1000s 2014 USD)")
		  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr
graph export abccare_disad_0.eps, replace

#delimit
twoway (lowess mdisad       age if male == 1 & age & age <= 44, lwidth(1.2) lpattern(solid) lcolor(gs8))
       (lowess mcontrol     age if male == 1 & age & age <= 44, lwidth(1.2) lpattern(solid) lcolor(gs0))
       
       (lowess pluscontrol  age   if male == 1 & age <= 44 ,  lpattern(dash) lcolor(gs0))
       (lowess minuscontrol age   if male == 1 & age <= 44,  lpattern(dash) lcolor(gs0))
       
       (lowess plusdisad  age if male == 1 & age <= 44,  lpattern(dash) lcolor(gs8))
       (lowess minusdisad age if male == 1 & age <= 44,  lpattern(dash) lcolor(gs8))
       
	(scatter real0  age                 if age == 30 & male == 1, mlcolor(black) mfcolor(white) msize(vlarge))
	(rcap    realplus0  realminus0 age  if age == 30 & male == 1, lcolor(black) lwidth(medthick))
       
        , 
        text( 37 34
         "ABC/CARE Eligible at t*: `mdisad301' (s.e. `sedisad301')"
	 " "
         "Synthetic Control Group at t*: `mcontrol301' (s.e. `secontrol301')"
         , size(small) place(nw) box just(left) margin(l+1 b+1 t+1 r+1) width(60) fcolor(none))
		  
		  
		  legend(rows(2) order(1 2 3 7 8) label(1 "ABC/CARE Eligible in PSID") label(2 "Synthetic Control Group-Matching Based") label(3 "+/- s.e.") 
		                              label(7 "Control Observed") label(8 "Observed +/- s.e.") size(vsmall))
		  xlabel(20 "20" 30 "Interpolation {&larr} t* {&rarr} Extrapolation" 40 "40", grid glcolor(gs14)) ylabel(10[10]50, angle(h) glcolor(gs14))
		  xtitle(Age) ytitle("Labor Income (1000s 2014 USD)")
		  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr
graph export abccare_disad_1.eps, replace


