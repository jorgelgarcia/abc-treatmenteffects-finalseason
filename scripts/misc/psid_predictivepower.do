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
global scripts     = "$projects/abc-treatmenteffects-finalseason/scripts/"
// ready data
global datapsid     = "$klmshare/Data_Central/data-repos/psid/base/"
global datapsidw    = "$klmshare/Data_Central/data-repos/psid/extensions/abc-match/"
global datanlsyw    = "$klmshare/Data_Central/data-repos/nlsy/extensions/abc-match-nlsy/"
global datacnlsyw   = "$klmshare/Data_Central/data-repos/nlsy/extensions/abc-match-cnlsy/"
global dataabccare  = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
global dataabcres   = "$klmmexico/abccare/income_projections"
global dataweights  = "$klmmexico/abccare/as_weights/"
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

reg si30y_inc_labor male black [aw=wtabc_allids_c3_control], robust
est sto psidZc

reg si30y_inc_labor male black [aw=wtabc_allids_c3_treat], robust
est sto psidZt

reg si30y_inc_labor male black years_30y [aw=wtabc_allids_c3_control], robust
est sto psidZXc

reg si30y_inc_labor male black years_30y [aw=wtabc_allids_c3_treat], robust
est sto psidZXt

reg si30y_inc_labor male black years_30y inc_labor21 [aw=wtabc_allids_c3_control], robust
est sto psidZLc

reg si30y_inc_labor male black years_30y inc_labor21 [aw=wtabc_allids_c3_treat], robust
est sto psidZLt

reg si30y_inc_labor male black years_30y inc_labor28 [aw=wtabc_allids_c3_control], robust
est sto psidZL1c

reg si30y_inc_labor male black years_30y inc_labor28 [aw=wtabc_allids_c3_treat], robust
est sto psidZL1t

cd $output
outreg2 [psidZc psidZt psidZXc psidZXt psidZLc psidZLt psidZL1c psidZL1t] using psid_predict, replace tex(frag) alpha(.01, .05, .10) sym (***, **, *) dec(2) par(se) r2 nonotes

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

reg si30y_inc_labor male black [aw=wtabc_allids_c3_control], robust
est sto nlsyZc

reg si30y_inc_labor male black [aw=wtabc_allids_c3_treat], robust
est sto nlsyZt

reg si30y_inc_labor male black years_30y [aw=wtabc_allids_c3_control], robust
est sto nlsyZXc

reg si30y_inc_labor male black years_30y [aw=wtabc_allids_c3_treat], robust
est sto nlsyZXt

reg si30y_inc_labor male black years_30y inc_labor21 [aw=wtabc_allids_c3_control], robust
est sto nlsyZLc

reg si30y_inc_labor male black years_30y inc_labor21 [aw=wtabc_allids_c3_treat], robust
est sto nlsyZLt

reg si30y_inc_labor male black years_30y inc_labor28 [aw=wtabc_allids_c3_control], robust
est sto nlsyZL1c

reg si30y_inc_labor male black years_30y inc_labor28 [aw=wtabc_allids_c3_treat], robust
est sto nlsyZL1t

cd $output
outreg2 [nlsyZc nlsyZt nlsyZXc nlsyZXt nlsyZLc nlsyZLt nlsyZL1c nlsyZL1t] using nlsy_predict, replace tex(frag) alpha(.01, .05, .10) sym (***, **, *) dec(2) par(se) r2 nonotes


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

reg si30y_inc_labor male black m_ed0y [aw=wtabc_allids_c3_control], robust
est sto cnlsyZc

reg si30y_inc_labor male black m_ed0y piatmath years_30y si21y_inc_labor si34y_bmi [aw=wtabc_allids_c3_control], robust
est sto cnlsyZXc

reg si30y_inc_labor male black m_ed0y piatmath years_30y si34y_bmi inc_labor28 [aw=wtabc_allids_c3_control], robust
est sto cnlsyZLc

reg si30y_inc_labor male black m_ed0y [aw=wtabc_allids_c3_treat], robust
est sto cnlsyZt

reg si30y_inc_labor male black m_ed0y piatmath years_30y si21y_inc_labor si34y_bmi [aw=wtabc_allids_c3_treat], robust
est sto cnlsyZXt

reg si30y_inc_labor male black m_ed0y piatmath years_30y si34y_bmi inc_labor28 [aw=wtabc_allids_c3_treat], robust
est sto cnlsyZLt


cd $output
outreg2 [cnlsyZc cnlsyZt cnlsyZXc cnlsyZXt cnlsyZLc cnlsyZLt] using cnlsy_predict, replace tex(frag) alpha(.01, .05, .10) sym (***, **, *) dec(2) par(se) r2 nonotes
