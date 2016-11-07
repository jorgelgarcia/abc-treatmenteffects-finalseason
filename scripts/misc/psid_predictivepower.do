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

// CNLSY
cd $dataweights
// get one match per individual in abc
use cnlsy-weights-finaldata.dta, clear
keep if draw == 0

keep id wtabc_id68_c3_treat-wtabc_id152_c3_treat wtabc_id78_c3_control-wtabc_id985_c3_control

foreach num of numlist 64(1)985 {
	capture rename  wtabc_id`num'_c3_treat    wtabc_id_treat`num'
	capture rename  wtabc_id`num'_c3_control  wtabc_id_control`num'
}

reshape long wtabc_id_treat wtabc_id_control, i(id) j(abcid)
replace wtabc_id_treat     = 1/wtabc_id_treat   if wtabc_id_treat != 0
replace wtabc_id_control   = 1/wtabc_id_control if wtabc_id_treat != 0
replace wtabc_id_treat     = 1 if wtabc_id_treat == 0
replace wtabc_id_control   = 1 if wtabc_id_control == 0

foreach group in treat control {
	preserve
	drop if wtabc_id_`group' == .
	bysort  abcid : egen `group' = min(wtabc_id_`group')
	replace wtabc_id_`group' = round(wtabc_id_`group',1)
	replace `group'      = round(`group',1)
	gen `group'ind = 1 if `group' == wtabc_id_`group'
	keep if `group'ind == 1
	keep id abcid
	tempfile `group'
	save "``group''"
	restore
}
use "`treat'", clear
append using "`control'"
// duplicates drop abcid, force
rename id cnlsyid 
rename abcid id

cd $dataabccare
merge m:1 id using append-abccare_iv, keepusing(D random male)
keep if _merge == 3
drop if random == 3
drop _merge
drop random

drop id 
rename cnlsyid id
tempfile matches
save   "`matches'", replace

cd $datacnlsyw
use cnlsy-abc-match.dta, clear
drop if black !=1 
merge m:m id using "`matches'"
keep if _merge == 3
drop    _merge

replace D = . if years_30y >= 10  & D == 0 & male == 0
replace D = . if years_30y <= 12  & D == 1 & male == 0

replace D = . if years_30y >= 9  & D == 0 & male == 1
replace D = . if years_30y <= 16  & D == 1 & male == 1

replace D = . if si30y_inc_labor >= 10000  & D == 0 & male == 1
replace D = . if si30y_inc_labor <  60000  & D == 1 & male == 1

keep male D inc_labor22-inc_labor30 inc_trans_pub22-inc_trans_pub30
tempfile cnlsy
save   "`cnlsy'", replace

// PSID
cd $dataweights
// get one match per individual in abc
use psid-weights-finaldata.dta, clear
keep if draw == 0

keep id wtabc_id68_c3_treat-wtabc_id152_c3_treat wtabc_id78_c3_control-wtabc_id985_c3_control

foreach num of numlist 64(1)985 {
	capture rename  wtabc_id`num'_c3_treat    wtabc_id_treat`num'
	capture rename  wtabc_id`num'_c3_control  wtabc_id_control`num'
}

reshape long wtabc_id_treat wtabc_id_control, i(id) j(abcid)
replace wtabc_id_treat     = 1/wtabc_id_treat   if wtabc_id_treat != 0
replace wtabc_id_control   = 1/wtabc_id_control if wtabc_id_treat != 0
replace wtabc_id_treat     = 1 if wtabc_id_treat == 0
replace wtabc_id_control   = 1 if wtabc_id_control == 0

foreach group in treat control {
	preserve
	drop if wtabc_id_`group' == .
	bysort  abcid : egen `group' = min(wtabc_id_`group')
	replace wtabc_id_`group' = round(wtabc_id_`group',1)
	replace `group'      = round(`group',1)
	gen `group'ind = 1 if `group' == wtabc_id_`group'
	keep if `group'ind == 1
	keep id abcid
	tempfile `group'
	save "``group''"
	restore
}
use "`treat'", clear
append using "`control'"
// duplicates drop abcid, force
rename id psidid 
rename abcid id

cd $dataabccare
merge m:1 id using append-abccare_iv, keepusing(D random male)
keep if _merge == 3
drop if random == 3
drop _merge
drop random

drop id 
rename psidid id
tempfile matches
save   "`matches'", replace

cd $datapsidw
use psid-abc-match.dta, clear
drop if black !=1 
merge m:m id using "`matches'"
keep if _merge == 3
drop    _merge

replace D = . if years_30y >= 9  & D == 0 & male == 0
replace D = . if years_30y <= 12  & D == 1 & male == 0

replace D = . if years_30y >= 10  & D == 0 & male == 1
replace D = . if years_30y <= 16  & D == 1 & male == 1

replace D = . if si30y_inc_labor >= 10000  & D == 0 & male == 1
replace D = . if si30y_inc_labor <  60000  & D == 1 & male == 1

keep male D inc_labor30-inc_labor67 inc_trans_pub30-inc_trans_pub67
tempfile psid
save   "`psid'", replace

// NLSY
cd $dataweights
// get one match per individual in abc
use nlsy-weights-finaldata.dta, clear
keep if draw == 0

keep id wtabc_id68_c3_treat-wtabc_id152_c3_treat wtabc_id78_c3_control-wtabc_id985_c3_control

foreach num of numlist 64(1)985 {
	capture rename  wtabc_id`num'_c3_treat    wtabc_id_treat`num'
	capture rename  wtabc_id`num'_c3_control  wtabc_id_control`num'
}

reshape long wtabc_id_treat wtabc_id_control, i(id) j(abcid)
replace wtabc_id_treat     = 1/wtabc_id_treat   if wtabc_id_treat != 0
replace wtabc_id_control   = 1/wtabc_id_control if wtabc_id_treat != 0
replace wtabc_id_treat     = 1 if wtabc_id_treat == 0
replace wtabc_id_control   = 1 if wtabc_id_control == 0

foreach group in treat control {
	preserve
	drop if wtabc_id_`group' == .
	bysort  abcid : egen `group' = min(wtabc_id_`group')
	replace wtabc_id_`group' = round(wtabc_id_`group',1)
	replace `group'      = round(`group',1)
	gen `group'ind = 1 if `group' == wtabc_id_`group'
	keep if `group'ind == 1
	keep id abcid
	tempfile `group'
	save "``group''"
	restore
}
use "`treat'", clear
append using "`control'"
// duplicates drop abcid, force
rename id nlsyid 
rename abcid id

cd $dataabccare
merge m:1 id using append-abccare_iv, keepusing(D random male)
keep if _merge == 3
drop if random == 3
drop _merge
drop random

drop id 
rename nlsyid id
tempfile matches
save   "`matches'", replace

cd $datanlsyw
use nlsy-abc-match.dta, clear
drop if black != 1
merge m:m id using "`matches'"
keep if _merge == 3
drop    _merge

replace D = . if years_30y >= 9  & D == 0 & male == 0
replace D = . if years_30y <= 12  & D == 1 & male == 0

replace D = . if years_30y >= 10  & D == 0 & male == 1
replace D = . if years_30y <= 16  & D == 1 & male == 1

replace D = . if si30y_inc_labor >= 10000  & D == 0 & male == 1
replace D = . if si30y_inc_labor <  60000  & D == 1 & male == 1

keep male D inc_labor30-inc_labor55 inc_trans_pub30-inc_trans_pub55
tempfile nlsy
save   "`nlsy'", replace

append using "`cnlsy'"
append using "`psid'"

foreach num of numlist 22(1)67 {
	replace inc_labor`num' = . if inc_labor`num' > 300000
	// replace inc_labor`num' = . if inc_labor`num' == 0
replace inc_labor`num' = (inc_labor`num')/(1 + .03)^`num'
}

egen inc_labor     = rowtotal(inc_labor*), missing
egen inc_trans_pub = rowtotal(inc_trans_pub*), missing 

// labor income
reg inc_labor D if male == 0
reg inc_labor D if male == 1
reg inc_labor D

// transfer income
qreg inc_trans_pub D if male == 0
qreg inc_trans_pub D if male == 1
qreg inc_trans_pub D



