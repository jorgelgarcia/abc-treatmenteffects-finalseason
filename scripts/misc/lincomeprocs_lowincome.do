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
global scripts      = "$projects/abc-treatmenteffects-finalseason/scripts/"
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

// cnlsy
cd $datacnlsyw
use cnlsy-abc-match.dta, clear
drop if black !=1 
keep id male m_ed0y piatmath si21y_inc_labor years_30y inc_labor22-inc_labor30
reshape long inc_labor, i(id) j(age)
xtset id age
bysort id: ipolate inc_labor age, gen(inc_labori) epolate
drop   inc_labor
rename inc_labori inc_labor

foreach age of numlist 22(1)30 {
	replace inc_labor = . if inc_labor > 75000 & age == `age'
	// replace inc_labor = . if inc_labor == 0 & age == `age'
}

gen   linc_labor = l.inc_labor

// autocorrelation 
xtgls inc_labor male m_ed0y piatmath years_30y si21y_inc_labor linc_labor, corr(ar1) force igls rhotype(dw) 
estimates store ar1cnlsy
cd $output
outreg2 [ar1cnlsy] using auto_cnlsy_lowinc, replace alpha(.01, .05, .10) sym (***, **, *) dec(3) par(se) r2 tex(frag)

// compute correlation
gen      rho = e(rho)
destring rho, replace 
summ     rho
matrix   cnlsyrho = [r(mean)]

cd $output
outtable using cnlsyrho_lowinc, mat(cnlsyrho) replace nobox center f(%9.3f)


// nlsy
cd $datanlsyw
use nlsy-abc-match.dta, clear
drop if black !=1 
keep id male si30y_inc_labor years_30y inc_labor31-inc_labor55
reshape long inc_labor, i(id) j(age)
xtset id age
bysort id: ipolate inc_labor age, gen(inc_labori) epolate
drop   inc_labor
rename inc_labori inc_labor

foreach age of numlist 31(1)55 {
	replace inc_labor = . if inc_labor > 75000 & age == `age'
	// replace inc_labor = . if inc_labor == 0 & age == `age'
}

tempfile nlsy
save "`nlsy'", replace

// psid
cd $datapsidw
use psid-abc-match.dta, clear
tostring id, replace
replace  id = id + "1000"
destring id, replace
drop if black !=1 
keep id male si30y_inc_labor years_30y inc_labor31-inc_labor67
reshape long inc_labor, i(id) j(age)
xtset id age
bysort id: ipolate inc_labor age, gen(inc_labori) epolate
drop   inc_labor
rename inc_labori inc_labor

foreach age of numlist 31(1)67 {
	replace inc_labor = . if inc_labor > 75000 & age == `age'
	// replace inc_labor = . if inc_labor == 0 & age == `age'
}

append using "`nlsy'"

xtset id age
gen   linc_labor = l.inc_labor

// autocorrelation 
xtgls inc_labor male years_30y si30y_inc_labor linc_labor, corr(ar1) force igls rhotype(dw) 
estimates store ar1psidnlsy

cd $output
outreg2 [ar1psidnlsy] using auto_nlsypsid_lowinc, replace alpha(.01, .05, .10) sym (***, **, *) dec(3) par(se) r2 tex(frag)

// compute correlation
gen      rho = e(rho)
destring rho, replace 
summ     rho
matrix   nlsypsidrho = [r(mean)]

cd $output
outtable using nlsypsidrho_lowinc, mat(nlsypsidrho) replace nobox center f(%9.3f)
