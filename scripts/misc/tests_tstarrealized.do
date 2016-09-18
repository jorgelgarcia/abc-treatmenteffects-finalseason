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
global datacnlsyp   = "$klmshare/Data_Central/data-repos/nlsy/primary/cnlsy/base"
global datapsidw    = "$klmshare/Data_Central/data-repos/psid/extensions/abc-match/"
global weights      = "$klmmexico/abccare/as_weights"
// output
global output       = "$projects/abc-treatmenteffects-finalseason/output/"

// realized
cd $dataabccare
use append-abccare_iv.dta, clear
summ si30y_inc_labor, d
drop if si30y_inc_labor > r(p99) 
drop if random == 3
summ R if male == 0
local N0 = r(N)
summ R if male == 1
local N1 = r(N)
replace si30y_inc_labor = si30y_inc_labor/1000
replace si21y_inc_labor = si21y_inc_labor/1000

foreach age  of numlist 21 30 { 
foreach male of numlist  0 1  {
foreach num  of numlist  0 1  {
	summ   si`age'y_inc_labor if R   == `num' & male == `male'
	local  labor`age'real_`num'm  = r(mean)
	local  labor`age'real_`num'sd = r(sd)
	local  labor`age'real_`num'se = `labor`age'real_`num'sd'/(sqrt(`N`male''))
	
	matrix labor`age'real_`num'`male'  = [`labor`age'real_`num'm',`labor`age'real_`num'se'] 
	
}
}
}

foreach age of numlist 21 30 {
matrix real`age' = J(1,5,.)
matrix colnames real`age' =  male real0 realse0 real1 realse1 
matrix labor`age'real_female = [0,labor`age'real_00,labor`age'real_10]
matrix colnames labor`age'real_female = male real0 realse0 real1 realse1
mat_rapp real`age' : real`age' labor`age'real_female

matrix labor`age'real_male   = [1,labor`age'real_01,labor`age'real_11]
mat colnames labor`age'real_male  = male real0 realse0 real1 realse1 
mat_rapp real`age' : real`age' labor`age'real_male

matrix real`age' = real`age'[2...,1...]
}

matrix real = [real21 \ real30]

clear 
svmat real, names(col)
gen age = _n
replace age = 21 if _n <= 2
replace age = 30 if _n  > 2

foreach age of numlist 21 30 {
	preserve
	keep if age == `age'
	tempfile real`age'
	save "`real`age''", replace
	
	reshape long real realse, i(male) j(R)
	gen realplus  = real + realse
	gen realminus = real - realse
	save "`real`age''", replace
	restore
}
use "`real21'", clear
append using "`real30'"

gen mean_age  = real      if age == 21
gen plus  = realplus  if age == 21
gen minus = realminus if age == 21 
save realpred.dta, replace
