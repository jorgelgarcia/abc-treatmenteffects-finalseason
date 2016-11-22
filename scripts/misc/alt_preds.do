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

// NLSY
cd $datanlsyw
use nlsy-abc-match.dta, clear
drop if black !=1 
keep id male years_30y inc_labor30-inc_labor55
reshape long inc_labor, i(id) j(age)
xtset id age
bysort id: ipolate inc_labor age, gen(inc_labori) epolate
drop   inc_labor
rename inc_labori inc_labor

foreach age of numlist 30(1)55 {
	replace inc_labor = . if inc_labor > 300000 & age == `age'
	// replace inc_labor = . if inc_labor == 0 & age == `age'
}
gen   linc_labor = l.inc_labor

// first : predict based on ar1 assumption
newey2 inc_labor linc_labor, lag(0) force
est sto model1

newey2 inc_labor linc_labor male years_30y, lag(0) force
est sto model2
matrix b1 = [e(b)] 

// second: based on differences model
// model in differences
gen  dinc_labor = d.inc_labor
gen ldinc_labor = l.dinc_labor

newey2 dinc_labor ldinc_labor, lag(0) force nocons
est sto model3
matrix b2 = [e(b)]

#delimit
outreg2 [model1 model2 model3] using auto_nlsy, replace
		alpha(.01, .05, .10) sym (***, **, *) dec(3) par(se) r2 tex(frag);
#delimit cr

// based on this, construct abc/care prediction
cd $dataabccare
use append-abccare_iv.dta, clear
drop if random == 3

// inconsistent
gen inc_labor30 = si30y_inc_labor
gen inc_labor21 = si21y_inc_labor

foreach num of numlist 22(1)29 {
	local numm1 = `num' - 1
	gen inc_labor`num' = b1[1,1]*inc_labor`numm1' + b1[1,2]*male + /// 
	                     b1[1,3]*years_30y + b1[1,4]
}

foreach num of numlist 31(1)67 {
	local numm1 = `num' - 1
	gen inc_labor`num' = b1[1,1]*inc_labor`numm1' + b1[1,2]*male + /// 
	                     b1[1,3]*years_30y + b1[1,4]
}

keep R male inc_labor30-inc_labor67 years_30y si30y_inc_labor si21y_inc_labor
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
