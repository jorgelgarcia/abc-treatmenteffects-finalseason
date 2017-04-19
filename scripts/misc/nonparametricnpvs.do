version 12.0
set more off
clear all
set matsize 11000

/*
Project :       ABC
Description:    PSID match test.
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
global collapseprj  = "$klmmexico/abccare/income_projections/current"
global dataabccare  = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
global datacnlsyw   = "$klmshare/Data_Central/data-repos/nlsy/extensions/abc-match-cnlsy/"
global datanlsyw    = "$klmshare/Data_Central/data-repos/nlsy/extensions/abc-match-nlsy/"
global datacnlsyp   = "$klmshare/Data_Central/data-repos/nlsy/primary/cnlsy/base"
global datapsidw    = "$klmshare/Data_Central/data-repos/psid/extensions/abc-match/"
global weights      = "$klmmexico/abccare/as_weights/current"
// output
global output       = "$projects/abc-treatmenteffects-finalseason/output/"

// obtain list of id's in abc-care
cd $dataabccare
use append-abccare_iv.dta, clear
keep if random != 3
levelsof id if R == 0, local(idscontrol)
levelsof id if R == 1, local(idstreat)

// PSID
cd $datapsidw
use psid-abc-match.dta, clear
keep if black == 1
keep id male years_30y inc_labor30-inc_labor67
reshape long inc_labor, i(id) j(age)
xtset id age
bysort id: ipolate inc_labor age, gen(inc_labori) epolate
drop   inc_labor
rename inc_labori inc_labor
replace inc_labor = . if inc_labor < 0 | inc_labor > 300000
replace inc_labor = . if inc_labor > 70000 & male == 0
reshape wide inc_labor, i(id) j(age)
keep id male years_30y inc_labor30-inc_labor67
tempfile psid 
save   "`psid'", replace 

cd $datapsidw
use psid-abc-match.dta, clear
keep id
tempfile id 
save   "`id'", replace 

cd $weights
use psid-weights-finaldata.dta, clear
keep id-wtabc_allids_c3_treat
merge m:1 id using "`id'"
keep if _merge == 3
drop _merge
save "`id'", replace
merge m:1 id using "`psid'"
keep if _merge == 3
drop _merge

global female & male == 0
global male & male == 1
global pooled

keep id-wtabc_allids_c3_treat inc_labor* male
drop wtabc_allids_c3_treat wtabc_allids_c3_control

// discount
foreach num of numlist 30(1)67 {
	replace inc_labor`num' = (inc_labor`num')/((1 + .03)^`num')
}

// total labor income 
egen inc_labor    = rowtotal(inc_labor30-inc_labor67), missing 
drop if inc_labor == .
drop inc_labor30-inc_labor67

global IDs 
foreach var of varlist wtabc_id78_c3_control-wtabc_id152_c3_treat {
	global IDs $IDs `var'
}

// weight per individual
foreach var of varlist $IDs {
	preserve
	capture collapse (mean) inc_labor [iw = `var'], by(draw male)
	capture rename inc_labor `var'
	
	capture tempfile `var'
	capture save "``var''", replace
	restore
}
	
// merge all individuals
use "`wtabc_id902_c3_control'", clear

foreach var in $IDs {
	capture merge 1:1 draw male using "``var''"
	capture drop if _merge == 2
	capture drop _merge
}

// by treatment and control
foreach group in control treat {
	egen npv_`group' = rowtotal(*_`group'), missing
}

gen  npv_te = npv_treat - npv_control
keep draw male npv_te

tempfile bygender
save   "`bygender'", replace

drop male
gen male = 2

append using "`bygender'"
collapse (mean) npv_te (semean) se_npv_te = npv_te, by(male)

mkmat *, matrix(inc_labor_npnpv)
cd $output
outtable using inc_labor_npnpv, mat(inc_labor_npnpv) replace nobox center f(%9.3f)
