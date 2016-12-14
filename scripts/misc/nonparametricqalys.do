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
global qalysresults = "$klmmexico/data-repos/psid/extensions/abc-match/current/"
global dataabccare  = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
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

// QALYs
cd $qalysresults
use abcwt_psid_all_12.dta, clear
keep if draw == 0
keep id male qaly*
keep id male qaly30-qaly100
// inflate to quality of life
foreach var of varlist qaly* {
	replace `var' = `var'*150000
}
tempfile qalys
save   "`qalys'", replace

// merge with weighted
cd $weights
use psid-weights-finaldata.dta, clear
keep id-wtabc_allids_c3_treat
merge m:1 id using "`qalys'"
keep if _merge == 3
drop _merge

/*
// weights
foreach group in treat control {
	foreach num of numlist `ids`group'' {
		replace wtabc_id`num'_c3_`group' = . if wtabc_id`num'_c3_`group' <= .735 & male == 0
	}
}
*/

keep id-wtabc_allids_c3_treat qaly* male
drop wtabc_allids_c3_treat wtabc_allids_c3_control

// discount
foreach num of numlist 30(1)100 {
	replace qaly`num' = (qaly`num')/((1 + .03)^`num')
}

// total labor income 
egen qaly    = rowtotal(qaly30-qaly100), missing 
drop if qaly == .
drop qaly30-qaly100

global IDs 
foreach var of varlist wtabc_id78_c3_control-wtabc_id152_c3_treat {
	global IDs $IDs `var'
}

// weight per individual
foreach var of varlist $IDs {
	preserve
	capture collapse (mean) qaly [iw = `var'], by(draw male)
	capture rename qaly `var'
	
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

mkmat *, matrix(qaly_npnpv)
cd $output
outtable using qaly_npnpv, mat(qaly_npnpv) replace nobox center f(%9.3f)
