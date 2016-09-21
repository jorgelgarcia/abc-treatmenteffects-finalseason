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
global datapsidp    = "$klmshare/Data_Central/data-repos/psid/base"
global datapsidw    = "$klmshare/Data_Central/data-repos/psid/extensions/abc-match/"
global weights      = "$klmmexico/abccare/as_weights"
// output
global output       = "$projects/abc-treatmenteffects-finalseason/output/"

set seed 0
// ABC/CARE
// get parental income profile
cd $dataabccare
use append-abccare_iv.dta, clear
keep if random != 3

replace m_ed4y6m = m_ed0y if m_ed4y6m == .
# delimit 
keep id birthyear R male m_age0y p_inc0y p_inc1y6m p_inc2y6m p_inc3y6m p_inc4y6m p_inc5y p_inc12y p_inc15y p_inc21y
	f_home0y f_home1y6m f_home2y6m f_home3y6m f_home4y6m f_home5y f_home8y
	m_work0y m_work1y6m m_work2y6m m_work3y6m m_work4y6m m_work5y m_work21y m_ed4y6m hh_sibs4y6m;
# delimit cr

rename hh_sibs4y6m hhchildren
gen m_birthyear = birthyear - m_age0y
drop birthyear
rename m_ed4y6m m_ed
rename p_inc0y    p_inc0
rename p_inc1y6m  p_inc2
rename p_inc2y6m  p_inc3
rename p_inc3y6m  p_inc4 
rename p_inc4y6m  p_inc5 
rename p_inc5y    p_inc6 
rename p_inc12y   p_inc12
rename p_inc15y   p_inc15
rename p_inc21y   p_inc21

rename f_home0y f_home0 
rename f_home1y6m f_home2 
rename f_home2y6m f_home3 
rename f_home3y6m f_home4 
rename f_home4y6m f_home5 
rename f_home5y   f_home6 
rename f_home8y   f_home8
gen f_home12 = f_home8
gen f_home15 = f_home8
gen f_home21 = f_home8

rename m_work0y   m_work0 
rename m_work1y6m m_work2 
rename m_work2y6m m_work3 
rename m_work3y6m m_work4 
rename m_work4y6m m_work5 
rename m_work5y   m_work6 
gen m_work8  = m_work6 
gen m_work12 = m_work6
rename m_work21y m_work21

// save ABC/CARE cross section
preserve
tempfile abccare
save   "`abccare'", replace
restore

// split income in two if father at home and mother works (~10% of sample)
reshape long p_inc f_home m_work, i(id) j(age)
replace p_inc = p_inc/2 if m_work == 1 & f_home == 1
gen m_age = m_age0y + age
gen m_experience  = m_age - m_ed - 6
gen m_experience2 = (m_experience)^2

// micer regression in the ABC/CARE sample
gen logp_inc = log(p_inc + 1)

// age, income, and education ranges
foreach var of varlist p_inc m_ed m_age hhchildren {
	summ `var'
	local min`var' = r(min)
	summ `var'
	local max`var' = r(max)
}
gen abccare = 1
tempfile abccare_pincome
save   "`abccare_pincome'"

// PSID
cd $datapsidp
use psid-base.dta, clear
keep if male == 0 & black == 1
keep id birthyear f_home* edu inc_labor* works* married* hhchildren*
reshape long f_home inc_labor works married hhchildren, i(id) j(year)
rename edu m_ed
rename works m_work
rename inc_labor p_inc
rename birthyear m_birthyear
rename married m_married
keep if m_married == 0

gen m_age = year - m_birthyear
gen m_experience  = m_age - m_ed - 6
gen m_experience2 = (m_experience)^2


// truncate to ABC/CARE ranges
foreach var of varlist p_inc m_ed m_age hhchildren {
	keep if `var' >= `min`var'' & `var' <= `max`var'' 
}
gen logp_inc = log(p_inc + 1)
gen abccare = 0

// append abc care 
append using "`abccare_pincome'"
drop if p_inc == 0
summ p_inc if abccare == 0, d
drop if p_inc >= r(p75) & abccare == 0

tempfile psidabc
save   "`psidabc'", replace

// mincer equations
foreach num of numlist 0 1 {
	reg logp_inc m_ed if abccare == `num', robust
	matrix          ed`num'       = e(b)
	matrix colnames ed`num'       = b1_m_ed_abccare`num' b1_cons_abccare`num'
	est sto         ed`num'
	
	reg logp_inc m_ed m_experience m_experience2 if abccare == `num', robust
	est sto         edexp`num'
	matrix          edexp`num'    = e(b)
	matrix colnames edexp`num'    = b2_m_ed_abccare`num' b2_m_experience_abccare`num' b2_m_experience2_abccare`num' b2_cons_abccare`num'
	
	reg logp_inc m_ed m_experience m_experience2 m_birthyear hhchildren if abccare == `num'
	est sto         edexpsib`num'
	matrix          edexpsib`num' = e(b)
	matrix colnames edexpsib`num' = b3_m_ed_abccare`num' b3_m_experience_abccare`num' b3_m_experience2_abccare`num' b3_m_birthyear`num' b3_hhchildren_abccare`num' b3_cons_abccare`num'	
}

cd $output
outreg2 [ed0 ed1 edexp0 edexp1 edexpsib0 edexpsib1] using abccarepsid_mincerests, replace tex(frag) alpha(.01, .05, .10) sym (***, **, *) dec(4) par(se) r2 nonotes

// construct matrix to then calculate treatment effects based on parameters
matrix psid_parameters = [ed0,edexp0,edexpsib0]
use "`abccare'", clear

// generate each of the three NPV estimates
gen predyearsworked = 65 - m_age0y
gen predyearsworkedfactor = 1/2*predyearsworked*(predyearsworked + 1)

collapse (mean) m_ed predyearsworked m_birthyear hhchildren, by(R male)
svmat psid_parameters, names(col)

// parametrize vectors
foreach var of varlist b1_* b2_* b3_* {
	summ `var'
	gen  `var'_r = r(mean)
	drop `var' 
	rename `var'_r `var'
}

# delimit
// to age 21
foreach num of numlist 0(1)60 {;
	gen PV3_`num' = (1/((1 + .03)^`num'))*exp(b3_m_ed_abccare0*m_ed + b3_m_experience_abccare0*predyearsworked + b3_m_experience2_abccare0*predyearsworked + b3_m_birthyear0*m_birthyear + b3_hhchildren_abccare0*hhchildren + b3_cons_abccare0);
};
# delimit cr

aorder
egen PV3_all40 = rowtotal(PV3_0-PV3_35), missing
egen PV3_all60 = rowtotal(PV3_0-PV3_55), missing

matrix p_inc40 = J(1,5,0)
matrix colnames p_inc40 = b n pooled male female
matrix p_inc60 = p_inc40
// bootstrap
foreach b of numlist 1(1)100 {
	use "`psidabc'", clear
	bsample

	reg logp_inc m_ed m_experience m_experience2 m_birthyear hhchildren if abccare == 0
	est sto         edexpsib`num'_`b'
	matrix          edexpsib`num'_`b' = e(b)
	matrix colnames edexpsib`num'_`b' = b3_m_ed_abccare`num' b3_m_experience_abccare`num' b3_m_experience2_abccare`num' b3_m_birthyear`num' b3_hhchildren_abccare`num' b3_cons_abccare`num'
	matrix psid_parameters = [edexpsib0]
	
	foreach n of numlist 1(1)100 {
	
	preserve
	use "`abccare'", clear
	bsample
	// generate each of the three NPV estimates
	gen predyearsworked = 65 - m_age0y
	gen predyearsworkedfactor = 1/2*predyearsworked*(predyearsworked + 1)

	collapse (mean) m_ed predyearsworked m_birthyear hhchildren, by(R male)
	svmat psid_parameters, names(col)

	// parametrize vectors
	foreach var of varlist b3_* {
		summ `var'
		gen  `var'_r = r(mean)
		drop `var' 
		rename `var'_r `var'
	}
	
	# delimit 
	// to age 21
	foreach num of numlist 0(1)60 {;
		gen PV3_`num' = (1/((1 + .03)^`num'))*exp(b3_m_ed_abccare0*m_ed + b3_m_experience_abccare0*predyearsworked + b3_m_experience2_abccare0*predyearsworked + b3_m_birthyear0*m_birthyear + b3_hhchildren_abccare0*hhchildren + b3_cons_abccare0);
	};
	# delimit cr

	aorder
	egen PV3_all40 = rowtotal(PV3_0-PV3_35), missing
	egen PV3_all60 = rowtotal(PV3_0-PV3_55), missing
	
	foreach age in 40 60 {
	reg PV3_all`age' R
	matrix pincpool_b`b'n`n' = e(b)
	matrix pincpool_b`b'n`n' = pincpool_b`b'n`n'[1,1]
	reg PV3_all`age' R if male == 0
	matrix pincfemale_b`b'n`n' = e(b)
	matrix pincfemale_b`b'n`n' = pincfemale_b`b'n`n'[1,1]
	reg PV3_all`age' R if male == 1
	matrix pincmale_b`b'n`n' = e(b)
	matrix pincmale_b`b'n`n' = pincmale_b`b'n`n'[1,1]
	
	matrix pinc_b`b'n`n' = [`b',`n',pincpool_b`b'n`n',pincfemale_b`b'n`n',pincmale_b`b'n`n']
	matrix colnames pinc_b`b'n`n' = b n pooled female male
	
	mat_rapp p_inc`age' : p_inc`age' pinc_b`b'n`n'
	}
	restore
	}
	
}
matrix p_inc40 = p_inc40[2...,1...]
matrix p_inc60 = p_inc60[2...,1...]

foreach num of numlist 40 60 {
clear 
svmat p_inc`num', names(col)
// output here if want to bootstrap
matrix p_incsum`num' = J(2,1,.)
matrix rownames p_incsum`num' = est pvalue
foreach var of varlist pooled male female {
	summ `var'
	local est`var' = r(mean)
	
	gen     `var'm   = r(mean)
	replace `var'    = `var' - r(mean)
	gen     `var'ind = 1
	replace `var'ind = 0 if `var'm > `var'
	
	summ `var'ind 
	local p`var' = r(mean)
	
	matrix `var' = [`est`var'' \ `p`var'']
	matrix rownames `var' = est pvalue
	matrix colnames `var' = `var'
	mat_capp p_incsum`num' : p_incsum`num' `var'
}
matrix p_incsum`num' = p_incsum`num'[1...,2...]
}
matrix p_incsum = [p_incsum40 \ p_incsum60]
cd $output
#delimit
outtable using abccarepsid_pincmincer, mat(p_incsum) replace nobox center f(%9.3f);
#delimit cr
