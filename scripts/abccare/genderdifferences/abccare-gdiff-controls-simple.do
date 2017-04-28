/*
Project: 	Treatment effects
Date:		April 27, 2017

This file:	Means of control group
*/

clear all
set more off

// parameters
set seed 1
global bootstraps 4
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

global abspun		home_abspun0y6m home_abspun1y6m home_abspun2y6m home_abspun3y6m home_abspun4y6m 
global abspuntype	factor

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
global crime		totfel totmis
global crimetype	factor

global si34y_bmi	si34y_bmi
global si34y_bmitype	var
global bp		si34y_sys_bp si34y_dia_bp
global bptype		factor

global varlist taske abspun crime si30y_inc_labor si34y_bmi
local numvars : word count $varlist

forvalues b = 0/$bootstraps {
	
	preserve
	
	if `b' > 0 {
		bsample
	}
	
	foreach v in $varlist {
		if "${`v'type}" == "factor" {
			gen `v' = .
			forvalues s = 0/1 {
				qui factor ${`v'} 
				qui predict `v'factor`s' if male == `s'
				qui sum `v'factor`s' if male == `s'
				qui replace `v'factor`s' = (`v'factor`s' - r(mean))/r(sd)
				//xtile `v'factor`s'_tmp = `v'factor`s', nquantiles($quantiles)
				//qui replace `v' = `v'factor`s'_tmp if male == `s'
				//drop `v'factor`s'_tmp `v'factor`s'
				replace `v' = `v'factor`s' if male == `s'
			}
		}
		else {
			gen `v'o = `v'
			forvalues s = 0/1 {
				sum `v' if male == `s'
				gen `v'`s' = (`v' - r(mean))/r(sd)
				//xtile `v'`s'_tmp = `v'`s', nquantiles($quantiles)
				//replace `v' = `v'`s'_tmp if male == `s'
				replace `v' = `v'`s' if male == `s'
			}
		}
		
		forvalues s = 0/1 {
			qui reg `v' R apgar1 apgar5 hrabc abc if male == `s' ``a'cond'
			matrix b`v'`s'`b' = e(b)

			matrix b`v'`s'`b'_R0 = b`v'`s'`b'[1,2]
			matrix b`v'`s'`b'_R1 = b`v'`s'`b'[1,1] //+ b`v'`a'`s'`b'[1,2]
			
			matrix b`v'`s'_R0 = (nullmat(b`v'`s'_R0) \ b`v'`s'`b'_R0)
			matrix colnames b`v'`s'_R0 = `v'_male`s'_R0
				
			matrix b`v'`s'_R1 = (nullmat(b`v'`s'_R1) \ b`v'`s'`b'_R1)
			matrix colnames b`v'`s'_R1 = `v'_male`s'_R1
		}
	}
	
	restore
}

// bring to data
local n = 0
foreach v in $varlist {
	local n = `n' + 1
	if `n' < `numvars'  {
		local formatrix `formatrix' b`v'0_R0, b`v'0_R1, b`v'1_R0, b`v'1_R1,
	}
	else {
		local formatrix `formatrix' b`v'0_R0, b`v'0_R1, b`v'1_R0, b`v'1_R1
	}
}
matrix all = `formatrix'

clear
svmat all, names(col)
gen draw = _n

// inference
foreach v in $varlist {
	forvalues s = 0/1 {
		forvalues r = 0/1 {
		
		sum `v'_male`s'_R`r' if draw == 1
		gen po_`v'_male`s'_R`r' = r(mean)
	
		sum `v'_male`s'_R`r' if draw > 1
		gen e_`v'_male`s'_R`r' = r(mean)
	
		gen de_`v'_male`s'_R`r' = `v'_male`s'_R`r' - e_`v'_male`s'_R`r' if draw > 1
	
		gen di_`v'_male`s'_R`r' = (abs(de_`v'_male`s'_R`r') >= abs(po_`v'_male`s'_R`r')) if draw > 1
		sum di_`v'_male`s'_R`r'
		gen p_`v'_male`s'_R`r' = r(mean)
		
		}
			
		gen add_`v'_male`s' = po_`v'_male`s'_R0 + po_`v'_male`s'_R1
		gen sub_`v'_male`s' = po_`v'_male`s'_R0 - po_`v'_male`s'_R1
	}
}


// graph

gen y0 = 0
local i = 1
foreach v in $varlist {
	
	gen n`i'_0 = `i'
	gen n`i'_1 = `i' + 0.25
	
	local i = `i' + 1
}


# delimit ;
twoway 	(bar po_taske_male0_R0 n1_0, barwidth(0.24) bfcol(black) blcol(black) blwidth(thick))
	
	(rbar po_taske_male0_R0 add_taske_male0 n1_0 	if po_taske_male0_R1 > 0 & p_taske_male0_R1 <= 0.1 , barwidth(0.24) bfcol(blue) blcol(blue) blwidth(thick))
	(rbar sub_taske_male0 po_taske_male0_R1 n1_0			if po_taske_male0_R1 < 0 & p_taske_male0_R1 <= 0.1 , barwidth(0.24) bfcol(purple) blcol(purple) blwidth(thick) lpattern(dash))
	(rbar po_taske_male0_R0 add_taske_male0 n1_0 	if po_taske_male0_R1 > 0 & p_taske_male0_R1 > 0.1 , barwidth(0.24) bfcol(white) blcol(blue) blwidth(thick))
	(rbar sub_taske_male0 po_taske_male0_R1 n1_0 			if po_taske_male0_R1 < 0 & p_taske_male0_R1 > 0.1 , barwidth(0.24) bfcol(white) blcol(purple) blwidth(thick) lpattern(dash))

	(bar po_taske_male1_R0 n1_1, barwidth(0.24) bfcol(gs8) blcol(gs8) blwidth(thick))
	
	(rbar po_taske_male1_R0 add_taske_male1 n1_1 	if po_taske_male1_R1 > 0 & p_taske_male1_R1 <= 0.1 , barwidth(0.24) bfcol(blue) blcol(blue) blwidth(thick))
	(rbar sub_taske_male1 po_taske_male1_R1 n1_1			if po_taske_male1_R1 < 0 & p_taske_male1_R1 <= 0.1 , barwidth(0.24) bfcol(purple) blcol(purple) blwidth(thick) lpattern(dash))
	(rbar po_taske_male1_R0 add_taske_male1 n1_1 	if po_taske_male1_R1 > 0 & p_taske_male1_R1 > 0.1 , barwidth(0.24) bfcol(white) blcol(blue) blwidth(thick))
	(rbar sub_taske_male1 po_taske_male1_R1 n1_1 			if po_taske_male1_R1 < 0 & p_taske_male1_R1 > 0.1 , barwidth(0.24) bfcol(white) blcol(purple) blwidth(thick) lpattern(dash))
	
(bar po_abspun_male0_R0 n2_0, barwidth(0.24) bfcol(black) blcol(black) blwidth(thick))
	
	(rbar po_abspun_male0_R0 add_abspun_male0 n2_0 	if po_abspun_male0_R1 > 0 & p_abspun_male0_R1 <= 0.1 , barwidth(0.24) bfcol(blue) blcol(blue) blwidth(thick))
	(rbar sub_abspun_male0 po_abspun_male0_R1 n2_0			if po_abspun_male0_R1 < 0 & p_abspun_male0_R1 <= 0.1 , barwidth(0.24) bfcol(purple) blcol(purple) blwidth(thick) lpattern(dash))
	(rbar po_abspun_male0_R0 add_abspun_male0 n2_0 	if po_abspun_male0_R1 > 0 & p_abspun_male0_R1 > 0.1 , barwidth(0.24) bfcol(white) blcol(blue) blwidth(thick))
	(rbar sub_abspun_male0 po_abspun_male0_R1 n2_0 			if po_abspun_male0_R1 < 0 & p_abspun_male0_R1 > 0.1 , barwidth(0.24) bfcol(white) blcol(purple) blwidth(thick) lpattern(dash))

	(bar po_abspun_male1_R0 n2_1, barwidth(0.24) bfcol(gs8) blcol(gs8) blwidth(thick))
	
	(rbar po_abspun_male1_R0 add_abspun_male1 n2_1 	if po_abspun_male1_R1 > 0 & p_abspun_male1_R1 <= 0.1 , barwidth(0.24) bfcol(blue) blcol(blue) blwidth(thick))
	(rbar sub_abspun_male1 po_abspun_male1_R1 n2_1			if po_abspun_male1_R1 < 0 & p_abspun_male1_R1 <= 0.1 , barwidth(0.24) bfcol(purple) blcol(purple) blwidth(thick) lpattern(dash))
	(rbar po_abspun_male1_R0 add_abspun_male1 n2_1 	if po_abspun_male1_R1 > 0 & p_abspun_male1_R1 > 0.1 , barwidth(0.24) bfcol(white) blcol(blue) blwidth(thick))
	(rbar sub_abspun_male1 po_abspun_male1_R1 n2_1 			if po_abspun_male1_R1 < 0 & p_abspun_male1_R1 > 0.1 , barwidth(0.24) bfcol(white) blcol(purple) blwidth(thick) lpattern(dash))
	
	(bar po_crime_male0_R0 n3_0, barwidth(0.24) bfcol(black) blcol(black) blwidth(thick))
	
	(rbar po_crime_male0_R0 add_crime_male0 n3_0 	if po_crime_male0_R1 > 0 & p_crime_male0_R1 <= 0.1 , barwidth(0.24) bfcol(blue) blcol(blue) blwidth(thick))
	(rbar sub_crime_male0 po_crime_male0_R1 n3_0			if po_crime_male0_R1 < 0 & p_crime_male0_R1 <= 0.1 , barwidth(0.24) bfcol(purple) blcol(purple) blwidth(thick) lpattern(dash))
	(rbar po_crime_male0_R0 add_crime_male0 n3_0 	if po_crime_male0_R1 > 0 & p_crime_male0_R1 > 0.1 , barwidth(0.24) bfcol(white) blcol(blue) blwidth(thick))
	(rbar sub_crime_male0 po_crime_male0_R1 n3_0 			if po_crime_male0_R1 < 0 & p_crime_male0_R1 > 0.1 , barwidth(0.24) bfcol(white) blcol(purple) blwidth(thick) lpattern(dash))

	(bar po_crime_male1_R0 n3_1, barwidth(0.24) bfcol(gs8) blcol(gs8) blwidth(thick))
	
	(rbar po_crime_male1_R0 add_crime_male1 n3_1 	if po_crime_male1_R1 > 0 & p_crime_male1_R1 <= 0.1 , barwidth(0.24) bfcol(blue) blcol(blue) blwidth(thick))
	(rbar sub_crime_male1 po_crime_male1_R1 n3_1			if po_crime_male1_R1 < 0 & p_crime_male1_R1 <= 0.1 , barwidth(0.24) bfcol(purple) blcol(purple) blwidth(thick) lpattern(dash))
	(rbar po_crime_male1_R0 add_crime_male1 n3_1 	if po_crime_male1_R1 > 0 & p_crime_male1_R1 > 0.1 , barwidth(0.24) bfcol(white) blcol(blue) blwidth(thick))
	(rbar sub_crime_male1 po_crime_male1_R1 n3_1 			if po_crime_male1_R1 < 0 & p_crime_male1_R1 > 0.1 , barwidth(0.24) bfcol(white) blcol(purple) blwidth(thick) lpattern(dash))

	(bar po_si30y_inc_labor_male0_R0 n4_0, barwidth(0.24) bfcol(black) blcol(black) blwidth(thick))
	
	(rbar po_si30y_inc_labor_male0_R0 add_si30y_inc_labor_male0 n4_0 	if po_si30y_inc_labor_male0_R1 > 0 & p_si30y_inc_labor_male0_R1 <= 0.1 , barwidth(0.24) bfcol(blue) blcol(blue) blwidth(thick))
	(rbar sub_si30y_inc_labor_male0 po_si30y_inc_labor_male0_R1 n4_0			if po_si30y_inc_labor_male0_R1 < 0 & p_si30y_inc_labor_male0_R1 <= 0.1 , barwidth(0.24) bfcol(purple) blcol(purple) blwidth(thick) lpattern(dash))
	(rbar po_si30y_inc_labor_male0_R0 add_si30y_inc_labor_male0 n4_0 	if po_si30y_inc_labor_male0_R1 > 0 & p_si30y_inc_labor_male0_R1 > 0.1 , barwidth(0.24) bfcol(white) blcol(blue) blwidth(thick))
	(rbar sub_si30y_inc_labor_male0 po_si30y_inc_labor_male0_R1 n4_0 			if po_si30y_inc_labor_male0_R1 < 0 & p_si30y_inc_labor_male0_R1 > 0.1 , barwidth(0.24) bfcol(white) blcol(purple) blwidth(thick) lpattern(dash))

	(bar po_si30y_inc_labor_male1_R0 n4_1, barwidth(0.24) bfcol(gs8) blcol(gs8) blwidth(thick))
	
	(rbar po_si30y_inc_labor_male1_R0 add_si30y_inc_labor_male1 n4_1 	if po_si30y_inc_labor_male1_R1 > 0 & p_si30y_inc_labor_male1_R1 <= 0.1 , barwidth(0.24) bfcol(blue) blcol(blue) blwidth(thick))
	(rbar sub_si30y_inc_labor_male1 po_si30y_inc_labor_male1_R1 n4_1			if po_si30y_inc_labor_male1_R1 < 0 & p_si30y_inc_labor_male1_R1 <= 0.1 , barwidth(0.24) bfcol(purple) blcol(purple) blwidth(thick) lpattern(dash))
	(rbar po_si30y_inc_labor_male1_R0 add_si30y_inc_labor_male1 n4_1 	if po_si30y_inc_labor_male1_R1 > 0 & p_si30y_inc_labor_male1_R1 > 0.1 , barwidth(0.24) bfcol(white) blcol(blue) blwidth(thick))
	(rbar sub_si30y_inc_labor_male1 po_si30y_inc_labor_male1_R1 n4_1 			if po_si30y_inc_labor_male1_R1 < 0 & p_si30y_inc_labor_male1_R1 > 0.1 , barwidth(0.24) bfcol(white) blcol(purple) blwidth(thick) lpattern(dash))

	(bar po_si34y_bmi_male0_R0 n5_0, barwidth(0.24) bfcol(black) blcol(black) blwidth(thick))
	
	(rbar po_si34y_bmi_male0_R0 add_si34y_bmi_male0 n5_0 	if po_si34y_bmi_male0_R1 > 0 & p_si34y_bmi_male0_R1 <= 0.1 , barwidth(0.24) bfcol(blue) blcol(blue) blwidth(thick))
	(rbar sub_si34y_bmi_male0 po_si34y_bmi_male0_R1 n5_0			if po_si34y_bmi_male0_R1 < 0 & p_si34y_bmi_male0_R1 <= 0.1 , barwidth(0.24) bfcol(purple) blcol(purple) blwidth(thick) lpattern(dash))
	(rbar po_si34y_bmi_male0_R0 add_si34y_bmi_male0 n5_0 	if po_si34y_bmi_male0_R1 > 0 & p_si34y_bmi_male0_R1 > 0.1 , barwidth(0.24) bfcol(white) blcol(blue) blwidth(thick))
	(rbar sub_si34y_bmi_male0 po_si34y_bmi_male0_R1 n5_0 			if po_si34y_bmi_male0_R1 < 0 & p_si34y_bmi_male0_R1 > 0.1 , barwidth(0.24) bfcol(white) blcol(purple) blwidth(thick) lpattern(dash))

	(bar po_si34y_bmi_male1_R0 n5_1, barwidth(0.24) bfcol(gs8) blcol(gs8) blwidth(thick))
	
	(rbar po_si34y_bmi_male1_R0 add_si34y_bmi_male1 n5_1 	if po_si34y_bmi_male1_R1 > 0 & p_si34y_bmi_male1_R1 <= 0.1 , barwidth(0.24) bfcol(blue) blcol(blue) blwidth(thick))
	(rbar sub_si34y_bmi_male1 po_si34y_bmi_male1_R1 n5_1			if po_si34y_bmi_male1_R1 < 0 & p_si34y_bmi_male1_R1 <= 0.1 , barwidth(0.24) bfcol(purple) blcol(purple) blwidth(thick) lpattern(dash))
	(rbar po_si34y_bmi_male1_R0 add_si34y_bmi_male1 n5_1 	if po_si34y_bmi_male1_R1 > 0 & p_si34y_bmi_male1_R1 > 0.1 , barwidth(0.24) bfcol(white) blcol(blue) blwidth(thick))
	(rbar sub_si34y_bmi_male1 po_si34y_bmi_male1_R1 n5_1 			if po_si34y_bmi_male1_R1 < 0 & p_si34y_bmi_male1_R1 > 0.1 , barwidth(0.24) bfcol(white) blcol(purple) blwidth(thick) lpattern(dash))
,
	
	graphregion(color(white))
	xlabel(0.25 "Females" 1.25 "Males")
	ylabel(, angle(0))
	
	legend(order(1 6 4 2 7 5 3) cols(3)	label(1 "Control, Female") label(6 "Control, Male") 
					label(4 "Positive Treat. Value Added")
					label(5 "Negative Treat. Value Added")
					label(2 "p-value {&le} 0.10")
					label(3 "p-value {&le} 0.10") size(vsmall))
	
	name(`v', replace)
;
# delimit cr

cd $output
graph export "control-simple-overview.eps", replace

