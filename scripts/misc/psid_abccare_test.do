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
global dataweights  = "$klmmexico/abccare/as_weights/weights_09122016"
global nlsyother    = "$klmmexico/BPSeason2"
global collapseprj  = "$klmmexico/abccare/income_projections/"

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
	foreach var of varlist male years_30y m_ed0y si30y_inc_labor si34y_bmi {
		summ `var' [aw=wtabc_allids_c3_control]
		mat  `var' = [r(mean) \ r(sd)]
		matrix colnames `var' =`var'
		mat rownames `var' = m se
		mat_capp allw : allw `var'
	}
matrix allwp = allw[1...,2...]

matrix allt = J(2,1,.)
matrix rownames allt = m se
	foreach var of varlist male years_30y m_ed0y si30y_inc_labor si34y_bmi {
		summ `var' [aw=wtabc_allids_c3_treat]
		mat  `var' = [r(mean) \ r(sd)]
		matrix colnames `var' =`var'
		mat rownames `var' = m se
		mat_capp allt : allt `var'
	}
matrix allpwt = allt[1...,2...]

matrix allw = J(2,1,.)
matrix rownames allw = m se
	foreach var of varlist male years_30y m_ed0y si30y_inc_labor si34y_bmi {
		summ `var'  if black == 1 & m_ed0y <= 12
		mat  `var' = [r(mean) \ r(sd)]
		matrix colnames `var' =`var'
		mat rownames `var' = m se
		mat_capp allw : allw `var'
	}
matrix allwpb = allw[1...,2...]

// nlsy
// drop non cross sectional
cd $nlsyother
use NLSY79MergedData_llk_short_V3.dta, clear
keep id cross_sect_weight CrossSectSample
keep if CrossSectSample == 1
keep if cross_sect_weight > 0 & cross_sect_weight !=.
tempfile cross
duplicates drop id, force
save "`cross'", replace

cd $datanlsyw
use  nlsy-abc-match.dta, clear
keep id black male years_30y si21y_inc_labor si30y_inc_labor inc_labor36
tempfile dandweights 
save   "`dandweights'", replace

merge 1:1 id using "`cross'"
keep if _merge == 3
drop _merge
tempfile cross
save "`dandweights'", replace

cd $dataweights
use nlsy-weights-finaldata.dta, clear
merge m:1 id using  "`dandweights'" 
keep if _merge == 3
drop _merge
save   "`dandweights'", replace

summ    si30y_inc_labor, d
replace si30y_inc_labor =. if si30y_inc_labor < r(p25)

matrix allw = J(2,1,.)
matrix rownames allw = m se
	foreach var of varlist male years_30y si21y_inc_labor si30y_inc_labor inc_labor36 {
		summ `var' [aw=wtabc_allids_c3_control]
		mat  `var' = [r(mean) \ r(sd)]
		matrix colnames `var' =`var'
		mat rownames `var' = m se
		mat_capp allw : allw `var'
	}
matrix allwn = allw[1...,2...]

matrix allt = J(2,1,.)
matrix rownames allt = m se
	foreach var of varlist male years_30y si21y_inc_labor si30y_inc_labor inc_labor36 {
		summ `var' [aw=wtabc_allids_c3_treat]
		mat  `var' = [r(mean) \ r(sd)]
		matrix colnames `var' =`var'
		mat rownames `var' = m se
		mat_capp allt : allt `var'
	}
matrix allnwt = allt[1...,2...]

matrix allw = J(2,1,.)
matrix rownames allw = m se
	foreach var of varlist male years_30y si21y_inc_labor si30y_inc_labor inc_labor36 {
		summ `var' if black == 1 & years_30y <= 12
		mat  `var' = [r(mean) \ r(sd)]
		matrix colnames `var' =`var'
		mat rownames `var' = m se
		mat_capp allw : allw `var'
	}
matrix allwnb = allw[1...,2...]

// cnlsy
cd $datacnlsyw
use  cnlsy-abc-match.dta, clear
keep id black male years_30y si21y_inc_labor si30y_inc_labor si34y_bmi m_ed0y
tempfile dandweights 
save   "`dandweights'", replace

cd $dataweights
use cnlsy-weights-finaldata.dta, clear
merge m:1 id using  "`dandweights'" 
keep if _merge == 3

matrix allw = J(2,1,.)
matrix rownames allw = m se
	foreach var of varlist male years_30y si21y_inc_labor si30y_inc_labor si34y_bmi  {
		summ `var' [aw=wtabc_allids_c3_control]
		mat  `var' = [r(mean) \ r(sd)]
		matrix colnames `var' =`var'
		mat rownames `var' = m se
		mat_capp allw : allw `var'
	}
matrix allwc = allw[1...,2...]

matrix allcwt = J(2,1,.)
matrix rownames allcwt = m se
	foreach var of varlist male years_30y si21y_inc_labor si30y_inc_labor si34y_bmi  {
		summ `var' [aw=wtabc_allids_c3_treat]
		mat  `var' = [r(mean) \ r(sd)]
		matrix colnames `var' =`var'
		mat rownames `var' = m se
		mat_capp allcwt : allcwt `var'
	}
matrix allcwt = allw[1...,2...]

matrix allw = J(2,1,.)
matrix rownames allw = m se
	foreach var of varlist male years_30y  si21y_inc_labor si30y_inc_labor si34y_bmi {
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
// there are some severe bmi outliers
foreach var of varlist si34y_bmi { 
	summ `var', d
	replace `var' = . if `var' > r(p90)
}

matrix alle = J(2,1,.)
matrix rownames alle = m se
	foreach var of varlist male years_30y si21y_inc_labor si30y_inc_labor si34y_bmi {
		summ `var' if R == 0
		mat  `var' = [r(mean) \ r(sd)]
		matrix colnames `var' =`var'
		mat rownames `var' = m se
		mat_capp alle : alle `var'
	}
matrix alle = alle[1...,2...]

matrix allet = J(2,1,.)
matrix rownames allet = m se
	foreach var of varlist male years_30y si21y_inc_labor si30y_inc_labor si34y_bmi {
		summ `var' if R == 1
		mat  `var' = [r(mean) \ r(sd)]
		matrix colnames `var' =`var'
		mat rownames `var' = m se
		mat_capp allet : allet `var'
	}
matrix allet = allet[1...,2...]

matrix fill = J(2,5,.)
mat all1 = [alle  \ allwp  \ allwn   \ allwc \ allwpb \ allwnb \ allwcb]
mat all2 = [allet \ allpwt \ allnwt  \ allcwt  \ fill   \ fill \ fill ]
mat all = [all1,all2]

// count males/females, control/treatment
summ R if R == 0 & male == 0
local N_00 = r(N)
summ R if R == 1 & male == 0
local N_10 = r(N)
summ R if R == 0 & male == 1
local N_01 = r(N)
summ R if R == 1 & male == 1
local N_11 = r(N)

// get predicted at age 30
cd $collapseprj
use labor_income_collapsed.dta, clear

// go back to standard deviations
foreach rand of numlist 0 1 {
	foreach male of numlist 0 1 {
		replace semean_age = semean_age*sqrt(`N_`rand'`male'')*1000 if R == `rand' & male == `male'
		replace mean_age   = mean_age*1000 if R == `rand' & male == `male'
	}
}
keep if age == 29 | age == 31
collapse (mean) mean_age sdmean_age = semean_age, by(R)
mkmat *, matrix(hojmantest)
matrix hojmantest = hojmantest'
matrix hojmantest = hojmantest[2...,1...]
matrix fill1 = J(2,3,.)
matrix fill2 = J(2,1,.)
matrix hojmantest = [fill1,hojmantest[1...,1],fill2,fill1,hojmantest[1...,2],fill2]
matrix rownames hojmantest = m se 
matrix allpred = [all[1..2,1...] \ hojmantest \ all[3...,1...]]

cd $output
#delimit
outtable using allsamplesmatch, 
mat(allpred) replace nobox center norowlab f(%9.3f);
#delimit cr
