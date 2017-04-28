/*
Project: 	Treatment effects
Date:		April 27, 2017

This file:	Means of control group
*/

clear all
set more off

// parameters
set seed 1
global bootstraps 50
global quantiles 30

// macros
global projects		: env projects
global klmshare		: env klmshare
global klmmexico	: env klmMexico

// filepaths
global data	   	= "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv"
global scripts    	= "$projects/abccare-cba/scripts/"
global output      	= "$projects/abccare-cba/output/"

local allcond
local homecond	& (dc_mo_pre == 0 & R == 0) | R == 1
local altcond & (dc_mo_pre > 0 & R == 0 & dc_mo_pre != .) | R == 1

// data
cd $data
use append-abccare_iv, clear

drop if R == 0 & RV == 1
keep if f_home0y == 0

global ind 		cbi_id5y6m cbi_id6y cbi_id6y6m cbi_id7y cbi_id7y6m cbi_id8y 
global indtype		factor

global taske		ibr_task0y6m ibr_task1y ibr_task1y6m
global tasketype	factor

global tasks		cbi_ta6y cbi_ta8y
global taskstype	factor

global sociabe		ibr_sociab0y6m ibr_sociab1y ibr_sociab1y6m
global sociabetype	factor

global iqe		vrb2y vrb3y 
global iqetype		factor

global iqs		vrb5y vrb8y
global iqstype		factor

global home		home0y6m home1y6m home2y6m home8y
global hometype		factor

global hs30y		hs30y
global hs30ytype 	var

global years_30y	years_30y
global years_30ytype	var

global si30y_inc_labor	si30y_inc_labor
global si30y_inc_labortype var

global totfel		totfel
global totfeltype	var
global totmis		totmis
global totmistype	var

global si34y_bmi	si34y_bmi
global si34y_bmitype	var
global bp		si34y_sys_bp si34y_dia_bp
global bptype		factor

global varlist totfel totmis si34y_bmi bp ind home hs21y taske tasks sociabe iqe iqs hs30y years_30y si30y_inc_labor
local numvars : word count $varlist

forvalues b = 0/$bootstraps {
	
	preserve
	
	if `b' > 0 {
		bsample
	}
	
	foreach v in $varlist {
		if "${`v'type}" == "factor" {
			gen `v' = .
			qui factor ${`v'} 
			qui predict `v'factor 
			qui sum `v'factor
			qui replace `v'factor = (`v'factor - r(mean))/r(sd)
			xtile `v'factor_tmp = `v'factor, nquantiles($quantiles)
			qui replace `v' = `v'factor_tmp 
			drop `v'factor_tmp `v'factor
				//replace `v' = `v'factor`s' if male == `s'
		}
		else {
			gen `v'o = `v'
			sum `v'
			gen `v's = (`v' - r(mean))/r(sd)
			xtile `v'_tmp = `v's, nquantiles($quantiles)
			replace `v' = `v'_tmp 
			//replace `v' = `v'`s' if male == `s'
		
		}
		
		forvalues s = 0/1 {
			foreach a in all home alt {
				qui reg `v' R /*apgar1 apgar5 hrabc abc*/ if male == `s' ``a'cond'
				matrix b`v'`a'`s'`b' = e(b)

				matrix b`v'`a'`s'`b'_R0 = b`v'`a'`s'`b'[1,2]
				matrix b`v'`a'`s'`b'_R1 = b`v'`a'`s'`b'[1,1] //+ b`v'`a'`s'`b'[1,2]
			
				matrix b`v'`a'`s'_R0 = (nullmat(b`v'`a'`s'_R0) \ b`v'`a'`s'`b'_R0)
				matrix colnames b`v'`a'`s'_R0 = `v'_`a'_male`s'_R0
				
				matrix b`v'`a'`s'_R1 = (nullmat(b`v'`a'`s'_R1) \ b`v'`a'`s'`b'_R1)
				matrix colnames b`v'`a'`s'_R1 = `v'_`a'_male`s'_R1
			}
		}
	}
	
	restore
}

// bring to data
local n = 0
foreach v in $varlist {
	foreach a in all home alt {
	
	local n = `n' + 1
		if `n' < `numvars' * 3 {
			local formatrix `formatrix' b`v'`a'0_R0, b`v'`a'0_R1, b`v'`a'1_R0, b`v'`a'1_R1,
		}
		else {
			local formatrix `formatrix' b`v'`a'0_R0, b`v'`a'0_R1, b`v'`a'1_R0, b`v'`a'1_R1
		}
	}
}
matrix all = `formatrix'

clear
svmat all, names(col)
gen draw = _n

// inference
foreach v in $varlist {
	foreach a in all home alt {
		forvalues s = 0/1 {
			forvalues r = 0/1 {
		
			sum `v'_`a'_male`s'_R`r' if draw == 1
			gen po_`v'_`a'_male`s'_R`r' = r(mean)
	
			sum `v'_`a'_male`s'_R`r' if draw > 1
			gen e_`v'_`a'_male`s'_R`r' = r(mean)
	
			sum `v'_`a'_male`s'_R`r' if draw > 1
			gen se_`v'_`a'_male`s'_R`r' = r(sd)
	
			gen u_`v'_`a'_male`s'_R`r' = po_`v'_`a'_male`s'_R`r' + se_`v'_`a'_male`s'_R`r'
			gen l_`v'_`a'_male`s'_R`r' = po_`v'_`a'_male`s'_R`r' - se_`v'_`a'_male`s'_R`r'
	
			gen de_`v'_`a'_male`s'_R`r' = `v'_`a'_male`s'_R`r' - e_`v'_`a'_male`s'_R`r' if draw > 1
	
			gen di_`v'_`a'_male`s'_R`r' = (abs(de_`v'_`a'_male`s'_R`r') >= abs(po_`v'_`a'_male`s'_R`r')) if draw > 1
			sum di_`v'_`a'_male`s'_R`r'
			gen p_`v'_`a'_male`s'_R`r' = r(mean)
		
			}
			
			gen add_`v'_`a'_male`s' = po_`v'_`a'_male`s'_R0 + po_`v'_`a'_male`s'_R1
		}
	}
}


// graph

gen y0 = 0
forvalues i = 0/1 {
	gen n`i'_all = `i'
	gen n`i'_home = `i' + 0.25
	gen n`i'_alt = `i' + 0.5
}

foreach v in $varlist {

# delimit ;
twoway 	(bar po_`v'_all_male0_R0 n0_all, barwidth(0.24) bfcol(black) blcol(black) blwidth(thick))
	(bar po_`v'_home_male0_R0 n0_home, barwidth(0.24) bfcol(gs8) blcol(gs8) blwidth(thick))
	(bar po_`v'_alt_male0_R0 n0_alt, barwidth(0.24) bfcol(gs5) blcol(gs5) blwidth(thick))
	(rbar po_`v'_all_male0_R0 add_`v'_all_male0 n0_all 	if po_`v'_all_male0_R1 > 0 & p_`v'_all_male0_R1 <= 0.1 , barwidth(0.24) bfcol(blue) blcol(blue) blwidth(thick))
	(rbar y0 po_`v'_all_male0_R1 n0_all 			if po_`v'_all_male0_R1 < 0 & p_`v'_all_male0_R1 <= 0.1 , barwidth(0.24) bfcol(purple) blcol(purple) blwidth(thick) lpattern(dash))
	(rbar po_`v'_all_male0_R0 add_`v'_all_male0 n0_all 	if po_`v'_all_male0_R1 > 0 & p_`v'_all_male0_R1 > 0.1 , barwidth(0.24) bfcol(white) blcol(blue) blwidth(thick))
	(rbar y0 po_`v'_all_male0_R1 n0_all 			if po_`v'_all_male0_R1 < 0 & p_`v'_all_male0_R1 > 0.1 , barwidth(0.24) bfcol(white) blcol(purple) blwidth(thick) lpattern(dash))
	(rbar po_`v'_alt_male0_R0 add_`v'_alt_male0 n0_alt 	if po_`v'_alt_male0_R1 > 0 & p_`v'_alt_male0_R1 <= 0.1 , barwidth(0.24) bfcol(blue) blcol(blue) blwidth(thick))
	(rbar y0 po_`v'_alt_male0_R1 n0_alt 			if po_`v'_alt_male0_R1 < 0 & p_`v'_alt_male0_R1 <= 0.1 , barwidth(0.24) bfcol(purple) blcol(purple) blwidth(thick lpattern(dash)))
	(rbar po_`v'_alt_male0_R0 add_`v'_alt_male0 n0_alt 	if po_`v'_alt_male0_R1 > 0 & p_`v'_alt_male0_R1 > 0.1 , barwidth(0.24) bfcol(white) blcol(blue) blwidth(thick))
	(rbar y0 po_`v'_alt_male0_R1 n0_alt 			if po_`v'_alt_male0_R1 < 0 & p_`v'_alt_male0_R1 > 0.1 , barwidth(0.24) bfcol(white) blcol(purple) blwidth(thick) lpattern(dash))
	(rbar po_`v'_home_male0_R0 add_`v'_home_male0 n0_home if po_`v'_home_male0_R1 > 0 & p_`v'_home_male0_R1 <= 0.1 , barwidth(0.24) bfcol(blue) blcol(blue) blwidth(thick))
	(rbar y0 po_`v'_home_male0_R1 n0_home 			if po_`v'_home_male0_R1 < 0 & p_`v'_home_male0_R1 <= 0.1 , barwidth(0.24) bfcol(purple) blcol(purple) blwidth(thick) lpattern(dash))
	(rbar po_`v'_home_male0_R0 add_`v'_home_male0 n0_home 	if po_`v'_home_male0_R1 > 0 & p_`v'_home_male0_R1 > 0.1 , barwidth(0.24) bfcol(white) blcol(blue) blwidth(thick))
	(rbar y0 po_`v'_home_male0_R1 n0_home 			if po_`v'_home_male0_R1 < 0 & p_`v'_home_male0_R1 > 0.1 , barwidth(0.24) bfcol(white) blcol(purple) blwidth(thick) lpattern(dash))
	
	(bar po_`v'_all_male1_R0 n1_all, barwidth(0.24) bfcol(black) blcol(black) blwidth(thick))
	(bar po_`v'_home_male1_R0 n1_home, barwidth(0.24) bfcol(gs8) blcol(gs8) blwidth(thick))
	(bar po_`v'_alt_male1_R0 n1_alt, barwidth(0.24) bfcol(gs5) blcol(gs5) blwidth(thick))
	(rbar po_`v'_all_male1_R0 add_`v'_all_male1 n1_all 	if po_`v'_all_male1_R1 > 0 & p_`v'_all_male1_R1 <= 0.1 , barwidth(0.24) bfcol(blue) blcol(blue) blwidth(thick))
	(rbar y0 po_`v'_all_male1_R1 n1_all 			if po_`v'_all_male1_R1 < 0 & p_`v'_all_male1_R1 <= 0.1 , barwidth(0.24) bfcol(purple) blcol(purple) blwidth(thick) lpattern(dash))
	(rbar po_`v'_all_male1_R0 add_`v'_all_male1 n1_all 	if po_`v'_all_male1_R1 > 0 & p_`v'_all_male1_R1 > 0.1 , barwidth(0.24) bfcol(white) blcol(blue) blwidth(thick))
	(rbar y0 po_`v'_all_male1_R1 n1_all 			if po_`v'_all_male1_R1 < 0 & p_`v'_all_male1_R1 > 0.1 , barwidth(0.24) bfcol(white) blcol(purple) blwidth(thick) lpattern(dash))
	(rbar po_`v'_alt_male1_R0 add_`v'_alt_male1 n1_alt 	if po_`v'_alt_male1_R1 > 0 & p_`v'_alt_male1_R1 <= 0.1 , barwidth(0.24) bfcol(blue) blcol(blue) blwidth(thick))
	(rbar y0 po_`v'_alt_male1_R1 n1_alt 			if po_`v'_alt_male1_R1 < 0 & p_`v'_alt_male1_R1 <= 0.1 , barwidth(0.24) bfcol(purple) blcol(purple) blwidth(thick) lpattern(dash))
	(rbar po_`v'_alt_male1_R0 add_`v'_alt_male1 n1_alt 	if po_`v'_alt_male1_R1 > 0 & p_`v'_alt_male1_R1 > 0.1 , barwidth(0.24) bfcol(white) blcol(blue) blwidth(thick))
	(rbar y0 po_`v'_alt_male1_R1 n1_alt 			if po_`v'_alt_male1_R1 < 0 & p_`v'_alt_male1_R1 > 0.1 , barwidth(0.24) bfcol(white) blcol(purple) blwidth(thick) lpattern(dash))
	(rbar po_`v'_home_male1_R0 add_`v'_home_male1 n1_home if po_`v'_home_male1_R1 > 0 & p_`v'_home_male1_R1 <= 0.1 , barwidth(0.24) bfcol(blue) blcol(blue) blwidth(thick))
	(rbar y0 po_`v'_home_male1_R1 n1_home 			if po_`v'_home_male1_R1 < 0 & p_`v'_home_male1_R1 <= 0.1 , barwidth(0.24) bfcol(purple) blcol(purple) blwidth(thick) lpattern(dash))
	(rbar po_`v'_home_male1_R0 add_`v'_home_male1 n1_home 	if po_`v'_home_male1_R1 > 0 & p_`v'_home_male1_R1 > 0.1 , barwidth(0.24) bfcol(white) blcol(blue) blwidth(thick))
	(rbar y0 po_`v'_home_male1_R1 n1_home 			if po_`v'_home_male1_R1 < 0 & p_`v'_home_male1_R1 > 0.1 , barwidth(0.24) bfcol(white) blcol(purple) blwidth(thick) lpattern(dash))
	
	,
	
	graphregion(color(white))
	xlabel(0.25 "Females" 1.25 "Males")
	ylabel(-4(4)24, angle(0))
	
	legend(order(1 6 4 2 7 5 3) cols(3)	label(1 "Control, All") label(2 "Control, Home") label(3 "Control, Alt.") 
					label(6 "Positive Treat. Value Added")
					label(7 "Negative Treat. Value Added")
					label(4 "p-value {&le} 0.10")
					label(5 "p-value {&le} 0.10") size(vsmall))
;
# delimit cr

cd $output
graph export "control-50a-fabsent-`v'.eps", replace
}
