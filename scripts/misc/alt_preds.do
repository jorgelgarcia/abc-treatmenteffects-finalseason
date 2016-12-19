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

set seed 0

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

tempfile cnlsy
save "`cnlsy'", replace

// psid
cd $datanlsyw
use nlsy-abc-match.dta, clear
drop if black !=1 
keep id male si30y_inc_labor years_30y inc_labor31-inc_labor55
reshape long inc_labor, i(id) j(age)
xtset id age
bysort id: ipolate inc_labor age, gen(inc_labori) epolate
drop   inc_labor
rename inc_labori inc_labor
tostring id, replace
replace  id = id + "1000"
destring id, replace

foreach age of numlist 31(1)55 {
	replace inc_labor = . if inc_labor > 300000 & age == `age'
	// replace inc_labor = . if inc_labor == 0 & age == `age'
}

append using "`cnlsy'"

tset id age
gen   linc_labor = l.inc_labor
gen  llinc_labor = l.linc_labor

tempfile cnlsynlsy
save   "`cnlsynlsy'", replace

matrix ball = [.,.,.]
foreach b of numlist 1(1)1000 {

	use "`cnlsynlsy'", clear
	bsample

	// parameterization 
	reg inc_labor male m_ed0y piatmath years_30y si21y_inc_labor linc_labor llinc_labor, robust 
	matrix b1 = e(b)
	// save vector of residuals to a matrix
	predict resid1, resid

	// parameterization
	reg inc_labor male years_30y si30y_inc_labor linc_labor llinc_labor, robust 
	matrix b2 = [e(b)]
	// save vector of residuals to a matrix 
	predict resid2, resid 

	summ resid1 if male == 1
	local var1male   = r(sd)
	summ resid1 if male == 0
	local var1female = r(sd)

	summ resid2 if male == 1
	local var2male   = r(sd)
	summ resid2 if male == 0
	local var2female = r(sd)

	// based on this, construct abc/care prediction
	cd $dataabccare
	use append-abccare_iv.dta, clear
	drop if random == 3
	bsample

	egen piatmath    = rowmean(piat_math5y6m piat_math6y piat_math6y6m) if program == "abc"
	egen piatmachcare = rowmean(wj_math5y6m wj_math6y wj_math7y6m)      if program == "care"
	replace piatmath = piatmachcare  if program == "care" 

	// inconsistent
	gen inc_labor30 = si30y_inc_labor
	gen inc_labor21 = si21y_inc_labor
	gen inc_labor20 = si21y_inc_labor
	
	foreach num of numlist 22(1)29 {
		gen draw`num'maley         =  rnormal(0,`var2male')
		gen draw`num'femaley       =  rnormal(0,`var2female')
	}
	egen drawmaley   = rowtotal(draw22male-draw29male)
	egen drawfemaley = rowtotal(draw22female-draw29female)
	

	foreach num of numlist 22(1)29 {
		local numm1 = `num' - 1
		local numm2 = `num' - 2
		gen inc_labor`num' = b1[1,1]*male + b1[1,2]*m_ed0y + b1[1,3]*piatmath + years_30y*b1[1,4] /// 
				   + si21y_inc_labor*b1[1,5] + b1[1,6]*inc_labor`numm1' + b1[1,7]*inc_labor`numm2' + b1[1,8] 
		
		gen draw`num'male       =  rnormal(0,`var1male')
		replace  inc_labor`num' =  inc_labor`num' + drawmaley   if male == 1
		
		gen draw`num'female     =  rnormal(0,`var1female')
		replace  inc_labor`num' =  inc_labor`num' + drawfemaley if male == 0
	}

	foreach num of numlist 31(1)67 {
		gen draw`num'male         =  rnormal(0,`var2male')
		gen draw`num'female       =  rnormal(0,`var2female')
	}
	egen draw drawmale = rowtotal(draw31male-draw67male)
	egen draw drawfemale = rowtotal(draw31female-draw67female)
	

	foreach num of numlist 31(1)67 {
		local numm1 = `num' - 1
		local numm2 = `num' - 2
		gen inc_labor`num' = b2[1,1]*male + /// 
				     b2[1,2]*years_30y + b2[1,3]*si30y_inc_labor +  b2[1,4]*inc_labor`numm1'  ///
				   + b2[1,5]*inc_labor`numm2' + b2[1,6] 
		
		gen draw`num'male       =  rnormal(0,`var2male')
		replace  inc_labor`num' =  inc_labor`num' + drawmale   if male == 1
		
		replace  inc_labor`num' =  inc_labor`num' + drawfemale if male == 0
	}

	keep R male m_ed0y piatmath years_30y si21y_inc_labor inc_labor21-inc_labor67 inc_labor30
	aorder

	foreach num of numlist 21(1)67 {
		replace inc_labor`num' = inc_labor`num'/((1 + .03)^`num')
	}
	egen inc_labor = rowtotal(inc_labor21-inc_labor67), missing
	
	reg inc_labor R if male == 1
	mat bmale = e(b)
	mat bmale = bmale[1,1]
	
	reg inc_labor R if male == 0
	mat bfemale = e(b)
	mat bfemale = bfemale[1,1]
	
	reg inc_labor R 
	mat bpooled = e(b)
	mat bpooled = bpooled[1,1]
	
	matrix b`num' = [bpooled,bmale,bfemale]
	matrix ball = [ball \ b`num']
}

matrix colnames ball = pooled male female

clear
svmat ball, names(col)

foreach var of varlist pooled male female {
	summ `var'
	mat `var' = [r(mean),r(sd)]
} 

matrix mat = [pooled \ male \ female]

cd $output
outtable using auto_npvmat, mat(mat) replace nobox center f(%9.3f)
