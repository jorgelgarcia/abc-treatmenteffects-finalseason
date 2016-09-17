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
global datacnlsyw    = "$klmshare/Data_Central/data-repos/nlsy/extensions/abc-match-cnlsy/"
global datapsidw    = "$klmshare/Data_Central/data-repos/psid/extensions/abc-match/"
global weights      = "$klmmexico/abccare/as_weights"
// output
global output       = "$projects/abc-treatmenteffects-finalseason/output/"

// ABC/CARE
// predicted at age 30
cd $collapseprj
use  labor_income_collapsed_pset1_mset3.dta, clear
keep if age >= 26 & age <= 34

collapse (mean) mean_age semean_age, by(R)
keep R mean_age semean_age 

foreach num of numlist 0 1 {
	foreach var of varlist mean_age semean_age {
		summ `var' if R == `num'
		local `var'_`num' = r(mean)
	}
	matrix labor30pred_`num' = [`mean_age_`num'' \ `semean_age_`num'']
}

// realized
cd $dataabccare
use append-abccare_iv.dta, clear
drop if random == 3
summ R
local N = r(N)

replace si30y_inc_labor = si30y_inc_labor/1000
foreach num of numlist 0 1 {
	summ   si30y_inc_labor if R   == `num'
	local  labor30real_`num'm  = r(mean)
	local  labor30real_`num'sd = r(sd)
	local  labor30real_`num'se = `labor30real_`num'sd'/(sqrt(`N'))
	
	matrix labor30real_`num'  = [`labor30real_`num'm' \ `labor30real_`num'se'] 
	
}

// psid 
// disadvantaged
cd $datapsidw 
use  psid-abc-match.dta, clear
drop if si30y_inc_labor > 300000
summ    si30y_inc_labor
replace si30y_inc_labor = si30y_inc_labor/1000
// disadvantaged
preserve
drop if black != 1 | m_ed0y > 12
collapse (mean) m=si30y_inc_labor (semean) se=si30y_inc_labor
mkmat *, matrix(labor30_psidB)
matrix labor30_psidB = labor30_psidB'
restore
keep id si30y_inc_labor
tempfile psidinc
save   "`psidinc'", replace

// weighted
cd $weights 
use psid-weights-finaldata.dta, clear
merge m:1 id using "`psidinc'"
keep if _merge == 3
drop _merge

// get N
preserve
duplicates drop id, force
des
local N = r(N)
restore

local numel = -1
foreach var in control treat {
	local numel = `numel' + 1
	summ si30y_inc_labor [iw = wtabc_allids_c3_`var']
	local m`var'  = r(mean)
	local se`var' = r(sd)/`N'
	
	matrix labor30psid_`numel' = [`m`var'' \ `se`var'']
}

// construct a matrix to output

matrix control   = [labor30real_0,labor30pred_0,labor30_psidB,labor30psid_0]
matrix treatment = [labor30real_1,labor30pred_1,J(2,1,.),labor30psid_1]

