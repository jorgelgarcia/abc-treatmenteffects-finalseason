/*
Project: 	Treatment effects
Date:		April 27, 2017

This file:	Means of control group
*/

clear all
set more off

// parameters
set seed 1
global bootstraps 100
global quantiles 30

// macros
global projects		: env projects
global klmshare		: env klmshare
global klmmexico	: env klmMexico

// filepaths
global data	   	= "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv"
global scripts    	= "$projects/abccare-cba/scripts/"
global output      	= "$projects/abccare-cba/output/"

// data
cd $data
use append-abccare_iv, clear

drop if R == 0 & RV == 1

// variables
cd ${scripts}/abccare/genderdifferences
include abccare-reverse
include abccare-outcomes

forvalues b = 0/$bootstraps {
	di "`b'"
	preserve
	
	if `b' > 0 {
		bsample
	}
	
	foreach c in `outcome_categories' {
		local counter0 = 0			// use to keep track of number Y_m - Y_f > 0
		local counter1 = 0
		local numvars : word count ``c'' 	// number of variables
	
		foreach v in ``c'' {
			
			forvalues s = 0/1 {
				qui sum `v' if male == `s' & R == 0 //& dc_mo_pre > 0 & dc_mo_pre != . //dc_mo_pre == 0 // 
				local b`v'`s'`b'_R0 = r(mean)
				qui sum `v' if male == `s' & R == 1
				local b`v'`s'`b'_R1 = r(mean)
				
			}
			if `b`v'1`b'_R0' - `b`v'0`b'_R0' > 0 {
				local counter0 = `counter0' + 1
			}
			if `b`v'1`b'_R1' - `b`v'0`b'_R1' > 0 {
				local counter1 = `counter1' + 1
			}
		}
		forvalues r = 0/1 {
			matrix `c'_prop`r'`b' = `counter`r'' / `numvars'
			matrix `c'_prop`r' = (nullmat(`c'_prop`r') \ `c'_prop`r'`b')
			matrix colnames `c'_prop`r' = `c'`r'
		}
	}
	
	restore
}

// bring to data
local n = 0
local numcats : word count `outcome_categories'

foreach c in `outcome_categories' {
	forvalues r = 0/1 {
		local n = `n' + 1
		if `n' < 2 * `numcats'  {
			local formatrix `formatrix' `c'_prop`r', 
		}
		else {
			local formatrix `formatrix' `c'_prop`r'
		}
	}
}
matrix all = `formatrix'


clear
svmat all, names(col)
gen draw = _n


// inference
foreach c in `outcome_categories' {
	forvalues r = 0/1 {
		// point estimate
		qui sum `c'`r' if draw == 1
		qui gen point_`c'`r' = r(mean)
	
		// empirical mean
		qui sum `c'`r' if draw > 1
		qui gen emp_`c'`r' = r(mean)
	
		// se
		qui gen se_`c'`r' = r(sd)
		qui gen u_`c'`r' = point_`c'`r' + se_`c'`r'
		qui gen l_`c'`r' = point_`c'`r' - se_`c'`r'
	
		// pvalue if different from 1/2
		qui gen dm_`c'`r' = `c'`r' - emp_`c'`r' + 0.50 if draw > 1
		qui gen diff_`c'`r' = (dm_`c'`r' > point_`c'`r') if draw > 1
		qui sum diff_`c'`r'
		qui gen p_`c'`r' = r(mean)
	
		qui gen diffl_`c'`r' = (dm_`c'`r' < point_`c'`r') if draw > 1
		qui sum diffl_`c'`r'
		qui gen pl_`c'`r' = r(mean)
	}
	// pvalue if different from each other
	qui gen `c'_0_1 = `c'1 - `c'0
	qui sum `c'_0_1 if draw == 1
	qui gen po_`c'_0_1 = r(mean)
	qui sum `c'_0_1 if draw > 1
	qui gen emp_`c'_0_1 = r(mean)
	qui gen dm_`c'_0_1 = `c'_0_1 - emp_`c'_0_1 if draw > 1
	qui gen diff3_`c'_0_1 = (abs(dm_`c'_0_1) > abs(po_`c'_0_1))
	qui sum diff3_`c'_0_1 if draw > 1
	qui gen p3_`c'_0_1 = r(mean)
}



// graph

qui gen y0 = 0
qui gen y1 = 1.125
local i = 1
foreach c in `outcome_categories' {
	
	qui gen n`c' = `i'
	
	local forgraph `forgraph' (bar point_`c'0 n`c', barwidth(0.5) bfcol(gs9) blcol(gs9) blwidth(thick))
	local forgraph `forgraph' (bar point_`c'1 n`c', barwidth(0.5) bfcol("54 83 91") blcol("54 83 91") blwidth(thick))
	if point_`c'0 < point_`c'1  {
		local forgraph `forgraph' (bar point_`c'0 n`c', barwidth(0.5) bfcol(gs9) blcol(gs9) blwidth(thick))
	}
	
	//local forgraph `forgraph' (rcap l_`c'0 u_`c'0 n`c', lcol(black))
	local forgraph `forgraph' (scatter point_`c'0 n`c' if p_`c'0 <= 0.101 | pl_`c'0 <= 0.101, msymb(square) mlcol(black) mcol(none) msize(large) yline(0.5, lcol(black) lwidth(thin)))
	local forgraph `forgraph' (scatter point_`c'1 n`c' if p_`c'1 <= 0.101 | pl_`c'1 <= 0.101, mlcol(black) mcol(none) msize(large) yline(0.5, lcol(black) lwidth(thin)))	
	local forgraph `forgraph' (scatter y1 n`c', msymb(none) mlab(p3_`c'_0_1) mlabcolor(black) mlabpos(0))
	local forlabel `forlabel' `i' "``c'_name'"
	
	local i = `i' + 1
}



# delimit ;
twoway 	`forgraph'
,	
	text(1.25 2.55 "{bf:H{subscript:0}: treatment {&ne} control (p-value)}", size(small))
	graphregion(color(white))
	xlabel(`forlabel', labsize(small) angle(45))
	ylabel(0(0.25)1, angle(0))
	ymtick(1.25, noticks)
	
	legend(order(- "{bf:Proportion Males > Females}" - 1 3 2 4) rows(3) label(1 "Control") label(2 "Treatment")
	label(3 "Reject: control proportion {&ne} 0.5")
	label(4 "Reject: treatment proportion {&ne} 0.5") 
	size(small))
;
# delimit cr

cd $output
graph export "gendergaps-treat-vs-fullcontrol.eps", replace


/*
// inference
foreach v in $varlist {
	// Y_m - Y_f 
	gen gd_`v'_R0 = `v'_male1_R0 - `v'_male0_R0 
		
	// point estimate of Y_m - Y_f
	sum gd_`v'_R0 if draw == 1
	gen gdpo_`v'_R0 = r(mean)
		
	// empirical mean of Y_m - Y_f
	sum gd_`v'_R0 if draw > 1
	gen gde_`v'_R0 = r(mean)
		
	// demean Y_m - Y_f
	gen gdde_`v'_R0 = gd_`v'_R0 - gde_`v'_R0 if draw > 1
		
	// calculate p-value
	gen gddi_`v'_R0 = (gdde_`v'_R0 > gdpo_`v'_R0) if draw > 1
	sum gddi_`v'_R0
	gen gdp_`v'_R0 = r(mean) 	
}
