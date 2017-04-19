version 12.0
set more off
clear all
set matsize 11000

/*
Project :       ABC CBA
Description:    predictive power of prediction variables, labor income
*This version:  April 18, 2016
*This .do file: Jorge L. Garcia
*This project : CBA Team  
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
global datanlsyw    = "$klmshare/Data_Central/data-repos/nlsy/extensions/abc-match-nlsy/"
global datacnlsyw   = "$klmshare/Data_Central/data-repos/nlsy/extensions/abc-match-cnlsy/"
global dataabccare  = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
global dataabcres   = "$klmmexico/abccare/income_projections"
global dataweights  = "$klmmexico/abccare/as_weights/current"
global nlsyother    = "$klmmexico/BPSeason2"
global collapseprj  = "$klmmexico/abccare/income_projections/"

// output
global output      = "$projects/abc-treatmenteffects-finalseason/output/"
set seed 0

// cnlsy
cd $datacnlsyw
use cnlsy-abc-match.dta, clear
drop if black !=1 
keep id male m_ed0y piatmath si21y_inc_labor years_30y inc_labor22-inc_labor30
reshape long inc_labor, i(id) j(age)
xtset id age
bysort id: ipolate inc_labor age, gen(inc_labori) epolate
drop   inc_labor
rename inc_labori inc_labor

foreach age of numlist 22(1)30 {
	replace inc_labor = . if inc_labor > 300000 & age == `age'
	// replace inc_labor = . if inc_labor == 0 & age == `age'
}

gen cnlsy = 1 
tempfile cnlsy
save "`cnlsy'", replace

// nlsy
cd $datanlsyw
use nlsy-abc-match.dta, clear
drop if black !=1 
keep id male si30y_inc_labor years_30y inc_labor31-inc_labor55
reshape long inc_labor, i(id) j(age)
xtset id age
bysort id: ipolate inc_labor age, gen(inc_labori) epolate
drop   inc_labor
rename inc_labori inc_labor
tostring id, replace
replace  id = id + "1000"
destring id, replace

foreach age of numlist 31(1)55 {
	replace inc_labor = . if inc_labor > 300000 & age == `age'
	// replace inc_labor = . if inc_labor == 0 & age == `age'
}
gen nlsy = 1
append using "`cnlsy'"

tset id age
gen   linc_labor = l.inc_labor
gen  llinc_labor = l.linc_labor

tempfile cnlsynlsy
save   "`cnlsynlsy'", replace

matrix ball = [.,.,.]
foreach b of numlist 1(1)100 {

	use "`cnlsynlsy'", clear
	keep id age inc_labor
	reshape wide inc_labor, i(id) j(age)
	
	bsample
	drop id 
	gen id = _n
	
	reshape long inc_labor, i(id) j(age)
	xtset id age

	// parameterization 
	xtabond inc_labor, robust
	matrix b1 = e(b)

	// based on this, construct abc/care prediction
	cd $dataabccare
	use append-abccare_iv.dta, clear
	drop if random == 3
	bsample
	drop id
	gen id = _n
	xtset id age

	gen inc_labor30 = si30y_inc_labor
	gen inc_labor21 = si21y_inc_labor
	
	foreach num of numlist 22(1)29 {
		local numm1 = `num' - 1
		gen inc_labor`num' = b1[1,2] + b1[1,1]*inc_labor`numm1'
	}
	
	keep id male R inc_labor*
	reshape long inc_labor, i(id) j(age)
	tsfill

	xtabond inc_labor, robust
	predict xb, xb
	gen resid = inc_labor - xb
	
	keep id age R male inc_labor resid
	reshape wide inc_labor resid, i(id) j(age)
	
	keep id male R resid* inc_labor21 inc_labor30
	drop resid21
	
	foreach num of numlist 22(1)29 31(1)67 {
		generate ui = floor((29-22+1)*runiform() + 22)
		summ     ui if id == 1
		local age = r(mean) 
		
		local numm1 = `num' - 1
		gen inc_labor`num' = b1[1,2] + b1[1,1]*inc_labor`numm1' + resid`age'
		
		drop ui
	}

	keep R male inc_labor21 inc_labor22-inc_labor67 inc_labor30
	aorder

	foreach num of numlist 21(1)67 {
		replace inc_labor`num' = inc_labor`num'/((1 + .03)^`num')
	}
	egen inc_labor = rowtotal(inc_labor21-inc_labor67), missing
	
	reg inc_labor R if male == 1
	mat bmale = e(b)
	mat bmale = bmale[1,1]
	
	reg inc_labor R if male == 0
	mat bfemale = e(b)
	mat bfemale = bfemale[1,1]
	
	reg inc_labor R 
	mat bpooled = e(b)
	mat bpooled = bpooled[1,1]
	
	matrix b`num' = [bpooled,bmale,bfemale]
	matrix ball = [ball \ b`num']
}

matrix colnames ball = pooled male female

clear
svmat ball, names(col)

foreach var of varlist pooled male female {
	summ `var'
	mat `var' = [r(mean),r(sd)]
} 

matrix mat = [pooled \ male \ female]

cd $output
outtable using auto_npvmat_ab, mat(mat) replace nobox center f(%9.3f)
