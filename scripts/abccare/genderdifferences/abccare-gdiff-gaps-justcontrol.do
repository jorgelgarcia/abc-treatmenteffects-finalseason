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
	
	preserve
	
	if `b' > 0 {
		bsample
	}
	
	foreach c in `outcome_categories' {
		local counter = 0			// use to keep track of number Y_m - Y_f > 0
		local numvars : word count ``c'' 	// number of variables
	
		foreach v in ``c'' {
			
			forvalues s = 0/1 {
				qui reg `v' R /*apgar1 apgar5 hrabc abc*/ if male == `s' 
				matrix b`v'`s'`b' = e(b)

				local b`v'`s'`b'_R0 = b`v'`s'`b'[1,2]
			}
			
			if `b`v'1`b'_R0' - `b`v'0`b'_R0' > 0 {
				local counter = `counter' + 1
			}
		}
		matrix `c'_prop`b' = `counter' / `numvars'
		//di "`c' prop `b': `counter'/`numvars'"
		matrix `c'_prop = (nullmat(`c'_prop) \ `c'_prop`b')
		matrix colnames `c'_prop = `c'
	}
	
	restore
}

// bring to data
local n = 0
local numcats : word count `outcome_categories'

foreach c in `outcome_categories' {
	local n = `n' + 1
	if `n' < `numcats'  {
		local formatrix `formatrix' `c'_prop, 
	}
	else {
		local formatrix `formatrix' `c'_prop
	}
}
matrix all = `formatrix'


clear
svmat all, names(col)
gen draw = _n


// inference
foreach c in `outcome_categories' {
	
	// point estimate
	qui sum `c' if draw == 1
	qui gen point_`c' = r(mean)
	
	// empirical mean
	qui sum `c' if draw > 1
	qui gen emp_`c' = r(mean)
	
	// se
	qui gen se_`c' = r(sd)
	qui gen u_`c' = point_`c' + se_`c'
	qui gen l_`c' = point_`c' - se_`c'
	
	// pvalue
	qui gen dm_`c' = `c' - emp_`c' + 0.50 if draw > 1
	qui gen diff_`c' = (dm_`c' > point_`c') if draw > 1
	qui sum diff_`c'
	qui gen p_`c' = r(mean)
	
}



// graph

qui gen y0 = 0
local i = 1
foreach c in `outcome_categories' {
	
	qui gen n`i' = `i'
	
	
	local forgraph `forgraph' (bar point_`c' n`i', barwidth(0.5) bfcol(gs8) blcol(gs8) blwidth(thick))
	local forgraph `forgraph' (rcap l_`c' u_`c' n`i', lcol(black))
	local forgraph `forgraph' (scatter point_`c' n`i' if p_`c' <= 0.10, mcol(black) msize(large) yline(0.5, lcol(black) lwidth(thin)))
	local forlabel `forlabel' `i' "``c'_name'"
	
	local i = `i' + 1
}


# delimit ;
twoway 	`forgraph'
,
	graphregion(color(white))
	xlabel(`forlabel', labsize(small) angle(45))
	ylabel(0(0.25)1, angle(0))
	
	legend(order(1 2 3) rows(3) label(1 "Proportion Control Males > Control Females") label(2 "+/- s.e.") label(3 "p-value {&le} 0.10"))
;
# delimit cr

cd $output
//graph export "control-simple-overview.eps", replace


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
