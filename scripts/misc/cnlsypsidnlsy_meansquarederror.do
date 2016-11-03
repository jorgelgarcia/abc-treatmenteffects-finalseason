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

// PSID
cd $dataweights
use psid-weights-finaldata.dta, clear
keep if draw == 0
tempfile psid
save "`psid'", replace

cd $datapsidw
use psid-abc-match.dta, clear
drop if si30y_inc_labor > 300000
merge 1:1 id using "`psid'"
keep if _merge == 3
drop _merge

gen psid = 1
save "`psid'", replace

// NLSY79
cd $dataweights
use nlsy-weights-finaldata.dta, clear
keep if draw == 0
tempfile nlsy
save "`nlsy'", replace

cd $datanlsyw
use nlsy-abc-match.dta, clear
drop if si30y_inc_labor > 300000
merge 1:1 id using "`nlsy'"
keep if _merge == 3
drop _merge

gen nlsy = 1
save "`nlsy'", replace

// CLSY
cd $dataweights
use cnlsy-weights-finaldata.dta, clear
keep if draw == 0
tempfile cnlsy
save "`cnlsy'", replace

cd $datacnlsyw
use cnlsy-abc-match.dta, clear
drop if si30y_inc_labor > 300000
merge 1:1 id using "`cnlsy'"
keep if _merge == 3
drop _merge

gen cnlsy = 1
save "`cnlsy'", replace

append using "`psid'"
append using "`nlsy'"


matrix rmsepreds = J(1,7,.)
matrix colnames rmsepreds =  mset1control mset1treat mset2control mset2treat mset3control mset3treat mset4 

// cnlsy predictions
foreach num of numlist 22(1)30 {
	matrix age`num' = [.]
	local numl = `num' - 2
	// weights by treatment and control
	foreach set in 1 2 3 {
		foreach group in control treat {
			reg inc_labor`num' male black piatmath years_30y inc_labor`numl' [aw=wtabc_allids_c`set'_`group'] if cnlsy == 1
			matrix age`num' = [age`num',e(rmse)]
		}
	}
	// no weights
	reg inc_labor`num' male black piatmath years_30y inc_labor`numl' if cnlsy == 1
	matrix age`num' = [age`num', e(rmse)]
	matrix age`num' = age`num'[1,2...]
	matrix colnames age`num' = mset1control mset1treat mset2control mset2treat mset3control mset3treat mset4 
	mat_rapp rmsepreds : rmsepreds age`num'
}	

// nlsy and psid
foreach num of numlist 31(1)65 {
	matrix age`num' = [.]
	local numl = `num' - 2
	// weights by treatment and control
	foreach set in 1 2 3 {
		foreach group in control treat {
			reg inc_labor`num' male black years_30y inc_labor`numl' [aw=wtabc_allids_c`set'_`group'] if nlsy == 1 | psid == 1
			matrix age`num' = [age`num',e(rmse)]
		}
	}
	// no weights
	reg inc_labor`num' male black years_30y inc_labor`numl' if nlsy | psid == 1
	matrix age`num' = [age`num', e(rmse)]
	matrix age`num' = age`num'[1,2...]
	matrix colnames age`num' = mset1control mset1treat mset2control mset2treat mset3control mset3treat mset4 
	mat_rapp rmsepreds : rmsepreds age`num'
}
matrix rmsepreds = rmsepreds[2...,1...]

// compute mean and standard error
clear
svmat rmsepreds, names(col)
preserve
collapse (semean) *
tempfile semean
save "`semean'", replace
restore

collapse (mean) *
append using "`semean'"
gen num = _n
gen     label = "mean"   if num == 1
replace label = "semean" if num == 2

cd $output
outsheet using rmse.csv, replace
