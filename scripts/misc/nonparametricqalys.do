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

global pooled
global female if male == 0
global male   if male == 1

foreach gen in pooled female male {
	reg years_30y treat ${`gen'}
	matrix b = e(b)
	matrix `gen'_mean   = b[1,2]
	matrix `gen'_meant  = b[1,1] + b[1,2] 
}

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
// replace inc_labor = . if inc_labor < 0 | inc_labor > 300000
// replace inc_labor = . if inc_labor > 70000 & male == 0
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

keep id-wtabc_allids_c3_treat inc_labor* male years_30y
drop wtabc_allids_c3_treat wtabc_allids_c3_control
tempfile id 
save   "`id'", replace

// QALYs
cd $qalysresults
use abcwt_psid_all_12.dta, clear
keep if draw == 0
keep id male qaly*
keep id male qaly25-qaly102
// inflate to quality of life
foreach var of varlist qaly* {
	// replace `var' = . if `var' > .8
	replace `var' = `var'*150000
}
tempfile qalys
save   "`qalys'", replace

use "`id'", clear
merge m:1 id using "`qalys'"
keep if _merge == 3
drop _merge

keep id-wtabc_id152_c3_treat qaly* male years_30y
// discount
foreach num of numlist 25(1)102 {
	replace qaly`num' = (qaly`num')/((1 + .03)^`num')
}

// total labor income 
egen qaly    = rowtotal(qaly25-qaly102), missing 
drop if qaly == .
drop qaly25-qaly102

global pooled
global female & male == 0
global male   & male == 1

/*
foreach gen in pooled female male {
	gen     `gen'_ind = 0 if years_30y <= 9    ${`gen'}
	replace `gen'_ind = 1 if years_30y  > 12    ${`gen'} 
}


