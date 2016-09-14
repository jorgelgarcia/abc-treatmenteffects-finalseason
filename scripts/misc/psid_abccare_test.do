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
global datacnlsyw    = "$klmshare/Data_Central/data-repos/nlsy/extensions/abc-match-cnlsy/"
global dataabccare  = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
global dataabcres   = "$klmmexico/abccare/income_projections"
global dataweights  = "$klmmexico/abccare/as_weights/weights_09122016"
// output
global output      = "$projects/abc-treatmenteffects-finalseason/output/"

// psid
cd $datapsidw
use  psid-abc-match.dta, clear
keep id male black birthyear years_30y si30y_inc_trans_pub si30y_inc_labor si34y_bmi m_ed0y
tempfile dandweights 
save   "`dandweights'", replace

cd $dataweights
use psid-weights-finaldata.dta, clear
merge m:1 id using  "`dandweights'" 
keep if _merge == 3

matrix allw = J(2,1,.)
matrix rownames allw = m se
	foreach var of varlist male years_30y  si30y_inc_labor si34y_bmi {
		summ `var' [aw=wtabc_allids_c3_control] if black == 1
		mat  `var' = [r(mean) \ r(sd)]
		matrix colnames `var' =`var'
		mat rownames `var' = m se
		mat_capp allw : allw `var'
	}
matrix allwp = allw[1...,2...]

matrix allw = J(2,1,.)
matrix rownames allw = m se
	foreach var of varlist male years_30y  si30y_inc_labor si34y_bmi {
		summ `var'  if black == 1 & m_ed0y <= 12
		mat  `var' = [r(mean) \ r(sd)]
		matrix colnames `var' =`var'
		mat rownames `var' = m se
		mat_capp allw : allw `var'
	}
matrix allwpb = allw[1...,2...]

// nlsy
cd $datanlsyw
use  nlsy-abc-match.dta, clear
keep id male black birthyear years_30y si30y_inc_labor si30y_inc_trans_pub 
tempfile dandweights 
save   "`dandweights'", replace

cd $dataweights
use nlsy-weights-finaldata.dta, clear
merge m:1 id using  "`dandweights'" 
keep if _merge == 3

matrix allw = J(2,1,.)
matrix rownames allw = m se
	foreach var of varlist male years_30y  si30y_inc_labor si30y_inc_trans_pub {
		summ `var' [aw=wtabc_allids_c3_control] if  years_30y >= 9 & black == 1
		mat  `var' = [r(mean) \ r(sd)]
		matrix colnames `var' =`var'
		mat rownames `var' = m se
		mat_capp allw : allw `var'
	}
matrix allwn = allw[1...,2...]

matrix allw = J(2,1,.)
matrix rownames allw = m se
	foreach var of varlist male years_30y  si30y_inc_labor si30y_inc_trans_pub {
		summ `var' if  years_30y >= 9 & black == 1 & years_30y <= 12
		mat  `var' = [r(mean) \ r(sd)]
		matrix colnames `var' =`var'
		mat rownames `var' = m se
		mat_capp allw : allw `var'
	}
matrix allwnb = allw[1...,2...]

// cnlsy
cd $datacnlsyw
use  cnlsy-abc-match.dta, clear
keep id male black birthyear years_30y si30y_inc_labor si34y_bmi m_ed0y
tempfile dandweights 
save   "`dandweights'", replace

cd $dataweights
use cnlsy-weights-finaldata.dta, clear
merge m:1 id using  "`dandweights'" 
keep if _merge == 3

matrix allw = J(2,1,.)
matrix rownames allw = m se
	foreach var of varlist male years_30y  si30y_inc_labor si34y_bmi {
		summ `var' [aw=wtabc_allids_c3_control]
		mat  `var' = [r(mean) \ r(sd)]
		matrix colnames `var' =`var'
		mat rownames `var' = m se
		mat_capp allw : allw `var'
	}
matrix allwc = allw[1...,2...]

matrix allw = J(2,1,.)
matrix rownames allw = m se
	foreach var of varlist male years_30y  si30y_inc_labor si34y_bmi {
		summ `var' if black == 1 & m_ed0y <=12
		mat  `var' = [r(mean) \ r(sd)]
		matrix colnames `var' =`var'
		mat rownames `var' = m se
		mat_capp allw : allw `var'
	}
matrix allwcb = allw[1...,2...]

cd $dataabccare
use append-abccare_iv.dta, clear
drop if random == 3
keep if R == 0

matrix alle = J(2,1,.)
matrix rownames alle = m se
	foreach var of varlist male years_30y si30y_inc_labor si34y_bmi {
		summ `var'
		mat  `var' = [r(mean) \ r(sd)]
		matrix colnames `var' =`var'
		mat rownames `var' = m se
		mat_capp alle : alle `var'
	}
matrix alle = alle[1...,2...]

mat all = [alle \ allwp \ allwn \ allwc \ allwpb \ allwnb \ allwcb]

cd $output
#delimit
outtable using allsamplesmatch, 
mat(all) replace nobox center f(%9.3f);
#delimit cr
