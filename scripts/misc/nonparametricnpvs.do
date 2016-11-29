version 12.0
set more off
clear all
set matsize 11000

/*
Project :       ABC
Description:    PSID match test.
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
global scripts      = "$projects/abc-treatmenteffects-finalseason/scripts/"
// ready data
global collapseprj  = "$klmmexico/abccare/income_projections/current"
global dataabccare  = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
global datacnlsyw   = "$klmshare/Data_Central/data-repos/nlsy/extensions/abc-match-cnlsy/"
global datanlsyw    = "$klmshare/Data_Central/data-repos/nlsy/extensions/abc-match-nlsy/"
global datacnlsyp   = "$klmshare/Data_Central/data-repos/nlsy/primary/cnlsy/base"
global datapsidw    = "$klmshare/Data_Central/data-repos/psid/extensions/abc-match/"
global weights      = "$klmmexico/abccare/as_weights/current"
// output
global output       = "$projects/abc-treatmenteffects-finalseason/output/"

// obtain list of id's in abc-care
cd $dataabccare
use append-abccare_iv.dta, clear
keep if random != 3
levelsof id if R == 0, local(idscontrol)
levelsof id if R == 1, local(idstreat)

// PSID
cd $datapsidw
use psid-abc-match.dta, clear
keep if black == 1
keep id male inc_labor30-inc_labor67
reshape long inc_labor, i(id) j(age)
xtset id age
bysort id: ipolate inc_labor age, gen(inc_labori) epolate
drop   inc_labor
rename inc_labori inc_labor
replace inc_labor = . if inc_labor < 0 | inc_labor > 300000
reshape wide inc_labor, i(id) j(age)
keep id male inc_labor30-inc_labor67
tempfile psid 
save   "`psid'", replace 

cd $datapsidw
use psid-abc-match.dta, clear
keep id
tempfile id 
save   "`id'", replace 

cd $weights
use psid-weights-finaldata.dta, clear
keep id-wtabc_allids_c3_treat
merge m:1 id using "`id'"
keep if _merge == 3
drop _merge
save "`id'", replace
merge m:1 id using "`psid'"
keep if _merge == 3
drop _merge

global female & male == 0
global male & male == 1
global pooled

// one data set per treatment group, per gender, and per draw
foreach group in treat control {
	foreach gender in male {
		foreach draw of numlist 0(1)2 {
		matrix inc_labor_`group'_`gender'_`draw' = J(1,39,.)
		
		
		foreach num of numlist `ids`group'' {
			matrix inc_labor_`group'_`gender'_`draw'_`num' = [.] 
			
			foreach age of numlist 30(1)67 {
				summ   inc_labor`age' [iw =  wtabc_id`num'_c3_`group'] if draw == `draw' ${`gender'} &  wtabc_id`num'_c3_`group' >= .74
				matrix inc_labor_`group'_`gender'_`draw'_`num' = [inc_labor_`group'_`gender'_`draw'_`num',r(mean)] 
			}
			matrix inc_labor_`group'_`gender'_`draw'_`num'   = [`num',inc_labor_`group'_`gender'_`draw'_`num'[1,2...]]
			matrix inc_labor_`group'_`gender'_`draw' = [inc_labor_`group'_`gender'_`draw' \ inc_labor_`group'_`gender'_`draw'_`num']
		}
		matrix   inc_labor_`group'_`gender'_`draw' = inc_labor_`group'_`gender'_`draw'[2...,1...]
		}
	}
}

// calculate NPVs (point estimates)
foreach draw of numlist 0(1)2 {
	foreach group in treat control {
		foreach gender in male {
		preserve
		clear 
		svmat inc_labor_`group'_`gender'_`draw', names(col)
		rename c1 id
		local num  = 1
		local numy = 29
		foreach var of varlist c* {
			local  num  = `num'  + 1
			local  numy = `numy' + 1 
			rename c`num' a`numy'
		}
		
		foreach num of numlist 30(1)67 {
			replace a`num' = a`num' / ((1 + .03)^`num')
		}
		
		egen a = rowtotal(a*), missing
		keep id a
		collapse (mean) a
		mkmat a, matrix(inc_labor_npv_`group'_`gender'_`draw')
		restore
		}
	}
}

// stack point estimates and bootstraps 
foreach group in treat control {
	foreach gender in male {
		matrix inc_labor_dist_`group'_`gender' = [.]
		foreach draw of numlist 0(1)2 {
			matrix inc_labor_dist_`group'_`gender' = [inc_labor_dist_`group'_`gender',inc_labor_npv_`group'_`gender'_`draw']
		}
	matrix inc_labor_dist_`group'_`gender' = [inc_labor_dist_`group'_`gender'[1,2...]]'
	}
}

// compute npv
foreach gender in male {
	preserve
	clear
	svmat inc_labor_dist_control_`gender', names(col)
	rename r1 control
	
	svmat inc_labor_dist_treat_`gender', names(col)
	rename r1 treatment
	
	gen npv = treatment - control
	
	gen draw = _n - 1
	summ npv if draw == 0
	local point = r(mean)
	drop if draw == 0
	
	summ npv
	local se = r(sd)
	replace npv = npv - r(mean)
	
	gen     ind = 0
	replace ind = 1 if npv > `point'
	
	summ ind
	local pvalue = r(mean) 
	
	matrix inc_labor_stats_`gender' = [`point',`se',`pvalue']
	restore
}

/*
// matrix output
matrix inc_labor_stats = [inc_labor_stats_pooled \ inc_labor_stats_male \ inc_labor_stats_female]
matrix rownames inc_labor_stats = pooled male female
matrix colnames inc_labor_stats = estimate se pvalue

cd $output
outtable using nonparametric_inc_labor_stats, mat(inc_labor_stats) replace nobox center f(%9.3f)


 
