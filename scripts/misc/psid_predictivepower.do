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
cd $datacnlsyw
use cnlsy-abc-match.dta, clear
drop if black !=1 
keep id male m_ed0y piatmath years_30y inc_labor21-inc_labor30
reshape long inc_labor, i(id) j(age)
xtset id age
bysort id: ipolate inc_labor age, gen(inc_labori) epolate
drop   inc_labor
rename inc_labori inc_labor

foreach age of numlist 21(1)30 {
	replace inc_labor = . if inc_labor > 300000 & age == `age'
	// replace inc_labor = . if inc_labor == 0 & age == `age'
}

gen   linc_labor = l.inc_labor

// autocorrelation 
xtgls inc_labor linc_labor male m_ed0y piatmath years_30y, corr(ar1) force igls rhotype(tscorr)  
estimates store ar1cnlsy

// compute correlation
gen      rho = e(rho)
destring rho, replace 
summ     rho
matrix   cnlsy = [r(mean)]

// bootstrap for standard error of rho
matrix rho = [.]
foreach num of numlist 1(1)100 {
preserve
bsample, cluster(id)
tostring id , replace
tostring age, replace
gen idage = id + age
duplicates drop idage, force
destring id , replace
destring age, replace

xtgls inc_labor linc_labor male m_ed0y piatmath years_30y, corr(ar1) force igls rhotype(tscorr)
gen      rhoest = e(rho)
destring rhoest, replace 
summ     rhoest
matrix rho = [rho \ r(mean)]
restore
}

preserve
clear
svmat   rho
drop if rho == .
summ    rho 
replace rho = (rho - r(mean)) - .5
gen     ind = 0
replace ind = 1 if abs(rho) > abs(cnlsy[1,1])
summ ind
matrix cnlsy = [cnlsy,r(mean)]
restore

// newey set-up
foreach num of numlist 0 1 2 {
	newey2 inc_labor linc_labor male m_ed0y piatmath years_30y, lag(`num') force
	estimates store lag`num'cnlsy
}

cd $output
// output regressions
#delimit
outreg2 [lag0cnlsy lag1cnlsy lag2cnlsy] using auto_cnlsy, replace
		alpha(.01, .05, .10) sym (***, **, *) dec(3) par(se) r2 tex(frag);
#delimit cr

// output rho and information
outtable using auto_rhocnlsy, mat(cnlsy) replace nobox center f(%9.3f)
