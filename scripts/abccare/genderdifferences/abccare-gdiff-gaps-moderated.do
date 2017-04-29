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
		foreach a in f h p {
			local counter`a' = 0			// use to keep track of number Y_m - Y_f > 0
		}
		local numvars : word count ``c'' 	// number of variables
	
		foreach v in ``c'' {
			
			forvalues s = 0/1 {
				//qui reg `v' R /*apgar1 apgar5 hrabc abc*/ if male == `s' 
				//matrix b`v'`s'`b' = e(b)
				//local b`v'`s'`b'_R0 = b`v'`s'`b'[1,2]
				//local b`v'`s'`b'_R1 = b`v'`s'`b'[1,1] + b`v'`s'`b'[1,2]
				
				qui sum `v' if male == `s' & R == 0 // full
				local `v'`s'`b'_R0_f = r(mean)
				
				qui sum `v' if male == `s' & R == 0 & dc_mo_pre == 0 // home
				local `v'`s'`b'_R0_h = r(mean)
				
				qui sum `v' if male == `s' & R == 0 & dc_mo_pre > 0 & !missing(dc_mo_pre) // alt. care
				local `v'`s'`b'_R0_p = r(mean)
			}
			
			foreach a in f h p {
				if ``v'1`b'_R0_`a'' - ``v'0`b'_R0_`a'' > 0 {
					local counter`a' = `counter`a'' + 1
				}
			}
		}
		
		foreach a in f h p {
			matrix `c'_prop`b'_`a' = `counter`a'' / `numvars'
			//di "`c' prop `b' `a': `counter`a''/`numvars'"
			matrix `c'_`a'_prop = (nullmat(`c'_`a'_prop) \ `c'_prop`b'_`a')
			matrix colnames `c'_`a'_prop = `c'`a'
		}
	}
	
	restore
}

// bring to data
local n = 0
local numcats : word count `outcome_categories'

foreach c in `outcome_categories' {
	foreach a in f h p {
		local n = `n' + 1
		if `n' < `numcats' * 3  {
			local formatrix `formatrix' `c'_`a'_prop, 
		}
		else {
			local formatrix `formatrix' `c'_`a'_prop
		}
	}
}
matrix all = `formatrix'


clear
svmat all, names(col)
gen draw = _n


// inference
foreach c in `outcome_categories' {
	
	foreach a in f h p {
		// point estimate
		qui sum `c'`a' if draw == 1
		qui gen point_`c'`a' = r(mean)
	
		// empirical mean
		qui sum `c'`a' if draw > 1
		qui gen emp_`c'`a' = r(mean)
	
		// se
		qui gen se_`c'`a' = r(sd)
		qui gen u_`c'`a' = point_`c'`a' + se_`c'`a'
		qui gen l_`c'`a' = point_`c'`a' - se_`c'`a'
	
		// pvalue
		qui gen dm_`c'`a' = `c'`a' - emp_`c'`a' + 0.50 if draw > 1
		qui gen diff_`c'`a' = (dm_`c'`a' > point_`c'`a') if draw > 1
		qui sum diff_`c'`a'
		qui gen p_`c'`a' = r(mean)
		
		qui gen diffl_`c'`a' = (dm_`c'`a' < point_`c'`a') if draw > 1
		qui sum diffl_`c'`a'
		qui gen pl_`c'`a' = r(mean)
	}
	
}



// graph
local barlookf	barwidth(0.9) bfcol(gs8) blcol(gs8) blwidth(thin)
local barlookh	barwidth(0.9) bfcol(white) blcol(black) blwidth(thin)
local barlookp	barwidth(0.9) bfcol(gs4) blcol(gs4) blwidth(thin)


qui gen y0 = 0
local i = 1
foreach c in `outcome_categories' {
	foreach a in f h p {
	
		qui gen n`i' = `i'
	
		local forgraph `forgraph' (bar point_`c'`a' n`i', `barlook`a'')
		local forgraph `forgraph' (rcap l_`c'`a' u_`c'`a' n`i', lcol(black) lwidth(vthin))
		local forgraph `forgraph' (scatter point_`c'`a' n`i' if p_`c'`a' <= 0.101 | pl_`c'`a' <= 0.101, mcol(black) msize(small) yline(0.5, lcol(black) lwidth(thin)))
		
		if "`a'" == "h" {
			local forlabel `forlabel' `i' "``c'_name'"
		}
		
		local i = `i' + 1
	}
	
	local i = `i' + 2
	
}


# delimit ;
twoway 	`forgraph'
,
	graphregion(color(white))
	xlabel(`forlabel', labsize(small) angle(45))
	ylabel(0(0.25)1, angle(0))
	
	legend(order(- "{bf:Proportion Males > Females}" - 1 2 4 3 7) rows(4) label(1 "Full Control Group") 
	label(4 "Stay at Home")
	label(7 "Alternative Preschool")
	label(2 "+/- s.e.") label(3 "p-value {&le} 0.10") size(vsmall))
;
# delimit cr

cd $output
graph export "gendergaps-control-moderated-altpre.eps", replace


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
