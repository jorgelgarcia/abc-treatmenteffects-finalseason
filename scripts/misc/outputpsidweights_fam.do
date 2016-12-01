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

global controledset & years_30y <=  12
global treatedset   & years_30y  >  12

// treatment 
foreach group in treat {
	foreach num of numlist `ids`group'' {
		replace wtabc_id`num'_c3_`group' = . if wtabc_id`num'_c3_`group' <= .6   & male == 0
		replace wtabc_id`num'_c3_`group' = . if wtabc_id`num'_c3_`group' <= .735 & male == 1 ${`group'edset}
	}
	
}
keep id-wtabc_allids_c3_treat male
saveold psid-weights-fam.dta, replace

