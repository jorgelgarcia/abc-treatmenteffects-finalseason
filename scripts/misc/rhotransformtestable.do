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
gen K = 0

egen piatmath    = rowmean(piat_math5y6m piat_math6y piat_math6y6m) if program == "abc"
egen piatmachcare = rowmean(wj_math5y6m wj_math6y wj_math7y6m)      if program == "care"
replace piatmath = piatmachcare  if program == "care" 

keep id R K male m_ed0y piatmath years_30y si21y_inc_labor si30y_inc_labor 

gen inc_labor20 = .
gen inc_labor23 = .
rename si21y_inc_labor inc_labor21  
rename si30y_inc_labor inc_labor22 

tempfile abc
save   "`abc'", replace

cd ${datacnlsyw}
use cnlsy-abc-match.dta, clear
gen K = 1
keep id K male m_ed0y piatmath years_30y si21y_inc_labor si30y_inc_labor

gen inc_labor20 = .
gen inc_labor23 = .
rename si21y_inc_labor inc_labor21  
rename si30y_inc_labor inc_labor22 

append using "`abc'"

reshape long inc_labor, i(id) j(age)
xtset id age 

bysort id: ipolate inc_labor age, gen(inc_labori) epolate
drop   inc_labor
rename inc_labori inc_labor

replace age = age - 20
replace inc_labor = 0 if inc_labor < 0

sort id age

// invariance: across samples
xtgls inc_labor K male m_ed0y piatmath years_30y l.inc_labor, corr(ar1) force igls rhotype(dw) 
est sto samples

// invariance: across treatment groups
xtgls inc_labor R male m_ed0y piatmath years_30y l.inc_labor, corr(ar1) force igls rhotype(dw) 
est sto groups

cd $output
outreg2 [samples groups] using rhotransform_testable, replace alpha(.01, .05, .10) sym (***, **, *) dec(3) par(se) r2 tex(frag)
