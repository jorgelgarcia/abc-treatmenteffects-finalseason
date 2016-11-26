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
	replace inc_labor = . if inc_labor > 300000 & age == `age'
	// replace inc_labor = . if inc_labor == 0 & age == `age'
}

gen   linc_labor = l.inc_labor

// autocorrelation 
xtgls inc_labor male m_ed0y piatmath years_30y si21y_inc_labor linc_labor, corr(ar1) force igls rhotype(dw) 
matrix b1 = e(b)

// compute correlation
gen      rho = e(rho)
destring rho, replace 
summ     rho
matrix   cnlsyrho = [r(mean)]

cd $output
outtable using cnlsyrho, mat(cnlsyrho) replace nobox center f(%9.3f)


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
	replace inc_labor = . if inc_labor > 300000 & age == `age'
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
	replace inc_labor = . if inc_labor > 300000 & age == `age'
	// replace inc_labor = . if inc_labor == 0 & age == `age'
}

append using "`nlsy'"

xtset id age
gen   linc_labor = l.inc_labor

// autocorrelation 
xtgls inc_labor male years_30y si30y_inc_labor linc_labor, corr(ar1) force igls rhotype(dw) 
matrix b2 = [e(b)]

// based on this, construct abc/care prediction
cd $dataabccare
use append-abccare_iv.dta, clear
drop if random == 3

// inconsistent
gen inc_labor30 = si30y_inc_labor
gen inc_labor21 = si21y_inc_labor

foreach num of numlist 22(1)29 {
	local numm1 = `num' - 1
	gen inc_labor`num' = b[1,1]*male + b[1,2]*m_ed0y + b[1,3]*piatmath + years_30y*b[1,4] /// 
	                   + si21y_inc_labor*b1[1,5] + b[1,6]*inc_labor`numm1' + b[1,7]
}

foreach num of numlist 31(1)67 {
	local numm1 = `num' - 1
	gen inc_labor`num' = b1[1,1]*male + /// 
	                     b1[1,2]*years_30y + b1[1,3]*inc_labor`numm1'  + b1[1,4]
}

keep R male m_ed0y piatmath years_30y si21y_inc_labor inc_labor21-inc_labor67
aorder

foreach num of numlist 21(1)67 {
	replace inc_labor`num' = inc_labor`num'/((1 + .03)^`num')
}
egen inc_labor = rowtotal(inc_labor21-inc_labor67), missing

// report NPV's
// female
reg inc_labor R if male == 0
matrix bfemale = e(b)
matrix Vfemale = e(V)

// male 
reg inc_labor R if male == 1
matrix bmale = e(b)
matrix Vmale = e(V)

// pooled
reg inc_labor R
matrix bpooled = e(b)
matrix Vpooled = e(V)


foreach sex in male female pooled { 
	matrix  b`sex' = b`sex'[1,1]
	matrix se`sex' = sqrt(V`sex'[1,1])
	matrix  p`sex' = 1 - normal(abs(b`sex'[1,1]/se`sex'[1,1]))
	matrix `sex'_1 = [b`sex',p`sex']
}

drop inc_labor*
gen inc_labor30 = si30y_inc_labor
gen inc_labor21 = si21y_inc_labor

foreach num of numlist 22(1)29 {
	local numm1 = `num' - 1
	gen inc_labor`num' = b2[1,1]*inc_labor`numm1'
}

foreach num of numlist 31(1)67 {
	local numm1 = `num' - 1
	gen inc_labor`num' = b2[1,1]*inc_labor`numm1'
}

foreach num of numlist 21(1)67 {
	replace inc_labor`num' = inc_labor`num'/((1 + .03)^`num')
}
egen inc_labor = rowtotal(inc_labor21-inc_labor67), missing

// report NPV's
// female
reg inc_labor R if male == 0
matrix bfemale = e(b)
matrix Vfemale = e(V)

// male 
reg inc_labor R if male == 1
matrix bmale = e(b)
matrix Vmale = e(V)

// pooled
reg inc_labor R
matrix bpooled = e(b)
matrix Vpooled = e(V)


foreach sex in male female pooled { 
	matrix  b`sex' = b`sex'[1,1]
	matrix se`sex' = sqrt(V`sex'[1,1])
	matrix  p`sex' = 1 - normal(abs(b`sex'[1,1]/se`sex'[1,1]))
	matrix `sex'_2 = [b`sex',p`sex']
}

foreach num of numlist 1 2 {
	matrix mat`num' = [pooled_`num',male_`num',female_`num']
}

matrix mat = [mat1 \ mat2]

cd $output
outtable using auto_npvmat, mat(mat) replace nobox center f(%9.3f)
