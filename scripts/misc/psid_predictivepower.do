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

egen  laggedincome = rowmean(inc_labor21 inc_labor22)
egen llaggedincome = rowmean(inc_labor27 inc_labor28)

egen  laggedtransfer = rowmean(inc_trans_pub21 inc_trans_pub22)
egen llaggedtransfer = rowmean(inc_trans_pub27 inc_trans_pub28)

replace piatmath = 1 if nlsy == 1 | psid == 1

foreach sample in psid nlsy cnlsy {

reg si30y_inc_labor male black piatmath years_30y     laggedincome llaggedincome [aw=wtabc_allids_c1_control] if `sample' == 1, robust
est sto `sample'incomet

reg si30y_inc_labor male black piatmath years_30y     laggedincome llaggedincome [aw=wtabc_allids_c1_treat]   if `sample' == 1, robust
est sto `sample'incomec

reg si30y_inc_trans_pub male black piatmath years_30y laggedtransfer llaggedtransfer [aw=wtabc_allids_c1_control] if `sample' == 1, robust
est sto `sample'transfert

reg si30y_inc_trans_pub male black piatmath years_30y laggedtransfer llaggedtransfer [aw=wtabc_allids_c1_treat]   if `sample' == 1, robust
est sto `sample'transferc

capture reg si34y_bmi male black piatmath years_30y laggedtransfer llaggedtransfer [aw=wtabc_allids_c1_control] if `sample' == 1, robust
capture est sto `sample'bmit

capture reg si34y_bmi male black piatmath years_30y laggedtransfer llaggedtransfer [aw=wtabc_allids_c1_treat]   if `sample' == 1, robust
capture est sto `sample'bmic

}

cd $output
outreg2 [cnlsyincomec cnlsyincomet nlsyincomec nlsyincomet psidincomec psidincomet] using combined_predict, replace tex(frag) alpha(.01, .05, .10) sym (***, **, *) dec(2) par(se) drop(o.piatmath) r2 nonotes
outreg2 [nlsytransferc nlsytransfert psidtransferc psidtransfert] using combined_predict_ti, replace tex(frag) alpha(.01, .05, .10) sym (***, **, *) dec(2) par(se) drop(o.piatmath) r2 nonotes

