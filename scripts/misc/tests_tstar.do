version 12.0
set more off
clear all
set matsize 11000

/*
Project :       ABC CARE
Description:    prediction vs. realized at t*
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
global scripts      = "$projects/abc-treatmenteffects-finalseason/scripts/"
// ready data
global collapseprj  = "$klmmexico/abccare/income_projections/current"
global dataabccare  = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
global datacnlsyw   = "$klmshare/Data_Central/data-repos/nlsy/extensions/abc-match-cnlsy/"
global datacnlsyp   = "$klmshare/Data_Central/data-repos/nlsy/primary/cnlsy/base"
global datapsidw    = "$klmshare/Data_Central/data-repos/psid/extensions/abc-match/"
global weights      = "$klmmexico/abccare/as_weights"
// output
global output       = "$projects/abccare-cba/output/"

// ABC/CARE
// predicted at age 30
cd $collapseprj
use  labor_income_collapsed_pset1_mset1.dta, clear
keep if age >= 25 & age <= 35

collapse (mean) mean_age semean_age, by(R male)
keep R mean_age semean_age male

foreach male of numlist 0 1 {
	foreach num of numlist 0 1 {
		foreach var of varlist mean_age semean_age {
			summ `var' if R == `num' & male == `male'
			local `var'_`num' = r(mean)
		}
		matrix labor30pred_`num'`male' = [`mean_age_`num'', `semean_age_`num'']
	}
}

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

foreach male of numlist 0 1 {
foreach num of numlist 0 1 {
	summ   si30y_inc_labor if R   == `num' & male == `male'
	local  labor30real_`num'm  = r(mean)
	local  labor30real_`num'sd = r(sd)
	local  labor30real_`num'se = `labor30real_`num'sd'/(sqrt(`N`male''))
	
	matrix labor30real_`num'`male'  = [`labor30real_`num'm',`labor30real_`num'se'] 
	
}
}

foreach var in pred real {
	matrix `var' = J(1,5,.)
	matrix colnames `var' =  male `var'0 `var'se0 `var'1 `var'se1 
	matrix labor30`var'_female = [0,labor30`var'_00,labor30`var'_10]
	mat colnames labor30`var'_female = male `var'0 `var'se0 `var'1 `var'se1
	mat_rapp `var' : `var' labor30`var'_female
	
	matrix labor30`var'_male   = [1,labor30`var'_01,labor30`var'_11]
	mat colnames labor30`var'_male  = male `var'0 `var'se0 `var'1 `var'se1 
	mat_rapp `var' : `var' labor30`var'_male
	
	matrix `var' = `var'[2...,1...]
}
matrix pred = pred[1...,2...]
matrix realpred = [real,pred]

clear 
svmat realpred, names(col)
gen age = 30
cd $output
save realpredwide.dta, replace

reshape long real realse pred predse, i(male) j(R)
gen realplus  = real + realse
gen realminus = real - realse
gen predplus  = pred + predse
gen predminus = pred - predse
save realpred.dta, replace
