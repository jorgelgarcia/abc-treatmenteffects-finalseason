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
global scripts        = "$projects/abc-treatmenteffects-finalseason/scripts/"
// ready data
global datapsidmatch   = "$klmshare/Data_Central/data-repos/psid/extensions/abc-match/"
global datanlsymatch   = "$klmshare/Data_Central/data-repos/nlsy/extensions/abc-match-nlsy/"
global dataCnlsymatch  = "$klmshare/Data_Central/data-repos/nlsy/extensions/abc-match-cnlsy/"
global dataabccare    = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
// output
global output      = "$projects/abc-treatmenteffects-finalseason/output/"

// PSID
cd $datapsidmatch
use psid-abc-match.dta, clear
drop if si30y_inc_labor > 300000

reg si30y_inc_labor male black [aw=wtabc_allids], robust
est sto psidZ

reg si30y_inc_labor male black years_30y [aw=wtabc_allids], robust
est sto psidZX

reg si30y_inc_labor male black years_30y inc_labor21 [aw=wtabc_allids], robust
est sto psidZL

reg si30y_inc_labor male black years_30y inc_labor28 [aw=wtabc_allids], robust
est sto psidZL1

cd $output
outreg2 [psidZ psidZX psidZL psidZL1] using psid_predict, replace tex(frag) alpha(.01, .05, .10) sym (***, **, *) dec(3) par(se) r2 nonotes

// NLSY79
cd $datanlsymatch
use nlsy-abc-match.dta, clear
drop if si30y_inc_labor > 300000

reg si30y_inc_labor male black [aw=wtabc_allids], robust
est sto nlsyZ

reg si30y_inc_labor male black years_30y [aw=wtabc_allids], robust
est sto nlsyZX

reg si30y_inc_labor male black years_30y inc_labor21 [aw=wtabc_allids], robust
est sto nlsyZL

reg si30y_inc_labor male black years_30y inc_labor28 [aw=wtabc_allids], robust
est sto nlsyZL1

cd $output
outreg2 [nlsyZ nlsyZX nlsyZL nlsyZL1] using nlsy_predict, replace tex(frag) alpha(.01, .05, .10) sym (***, **, *) dec(3) par(se) r2 nonotes

// CNLSY
cd $dataCnlsymatch
use cnlsy-abc-match.dta, clear
drop if si30y_inc_labor > 300000

reg si30y_inc_labor male black m_ed0y [aw=wtabc_allids], robust
est sto cnlsyZ

reg si30y_inc_labor male black m_ed0y piatmath years_30y si21y_inc_labor si34y_bmi [aw=wtabc_allids], robust
est sto cnlsyZX

reg si30y_inc_labor male black m_ed0y piatmath years_30y si34y_bmi inc_labor28 [aw=wtabc_allids], robust
est sto cnlsyZL

cd $output
outreg2 [cnlsyZ cnlsyZX cnlsyZL] using cnlsy_predict, replace tex(frag) alpha(.01, .05, .10) sym (***, **, *) dec(3) par(se) r2 nonotes

// ABC
cd $dataabccare
use append-abccare_iv.dta, clear
drop if random == 3

egen piatabc  = rowmean(piat5y6m piat6y piat6y6m piat7y)   if program == "abc"
egen piatcare = rowmean(wj_math5y6m wj_math6y wj_math7y6m) if program == "care"

gen     piatmath = piatabc  if program == "abc"
replace piatmath = piatcare if program == "care" 

reg si30y_inc_labor male m_ed0y, robust
est sto abcZ

reg si30y_inc_labor male m_ed0y piatmath years_30y si21y_inc_labor, robust
est sto abcZX

reg si30y_inc_labor male m_ed0y piatmath years_30y si21y_inc_labor si34y_bmi, robust
est sto abcZL

cd $output
outreg2 [abcZ abcZX abcZL] using abc_predict, replace tex(frag) alpha(.01, .05, .10) sym (***, **, *) dec(3) par(se) r2 nonotes

// ABC + treat
foreach var of varlist si30y_inc_labor male m_ed0y piatmath years_30y si21y_inc_labor si34y_bmi {
	gen treat`var' = treat*`var'
}

reg si30y_inc_labor treat male treatmale m_ed0y treatm_ed0y, robust
est sto abcZf

reg si30y_inc_labor treat male treatmale m_ed0y treatm_ed0y piatmath treatpiatmath years_30y treatyears_30y si21y_inc_labor treatsi21y_inc_labor, robust
est sto abcZXf

reg si30y_inc_labor treat male treatmale m_ed0y treatm_ed0y piatmath treatpiatmath years_30y treatyears_30y si21y_inc_labor treatsi21y_inc_labor si34y_bmi treatsi34y_bmi, robust
est sto abcZLf

cd $output
outreg2 [abcZf abcZXf abcZLf] using abc_predictf, replace tex(frag) alpha(.01, .05, .10) sym (***, **, *) dec(3) par(se) r2 nonotes

// females
reg si30y_inc_labor treat m_ed0y treatm_ed0y if male == 0, robust
est sto abcZff

reg si30y_inc_labor treat m_ed0y treatm_ed0y piatmath treatpiatmath years_30y treatyears_30y si21y_inc_labor treatsi21y_inc_labor if male == 0, robust
est sto abcZXff

reg si30y_inc_labor treat m_ed0y treatm_ed0y piatmath treatpiatmath years_30y treatyears_30y si21y_inc_labor treatsi21y_inc_labor si34y_bmi treatsi34y_bmi if male == 0, robust
est sto abcZLff

cd $output
outreg2 [abcZff abcZXff abcZLff] using abc_predictff, replace tex(frag) alpha(.01, .05, .10) sym (***, **, *) dec(3) par(se) r2 nonotes


// males
reg si30y_inc_labor treat m_ed0y treatm_ed0y if male == 1, robust
est sto abcZfm

reg si30y_inc_labor treat m_ed0y treatm_ed0y piatmath treatpiatmath years_30y treatyears_30y si21y_inc_labor treatsi21y_inc_labor if male == 1, robust
est sto abcZXfm

reg si30y_inc_labor treat m_ed0y treatm_ed0y piatmath treatpiatmath years_30y treatyears_30y si21y_inc_labor treatsi21y_inc_labor si34y_bmi treatsi34y_bmi if male == 1, robust
est sto abcZLfm

cd $output
outreg2 [abcZfm abcZXfm abcZLfm] using abc_predictfm, replace tex(frag) alpha(.01, .05, .10) sym (***, **, *) dec(3) par(se) r2 nonotes


