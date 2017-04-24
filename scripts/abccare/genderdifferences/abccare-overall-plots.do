/*
Project: 	Treatment effects
Date:		April 24, 2017
*/

clear all
set more off

// parameters
set seed 1
global bootstraps 5
global quantiles 25

// macros
global projects		: env projects
global klmshare		: env klmshare
global klmmexico	: env klmMexico

// filepaths
global data	   	= "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv"
global scripts    	= "$projects/abccare-cba/scripts/"
global output      	= "$projects/abccare-cba/output/"

// variables
# delimit ;
global home		home0y6m home1y6m home2y6m home8y;
global cog		vrb2y vrb3y vrb5y vrb8y;
global ncog		ibr_task0y6m ibr_task1y ibr_task1y6m cbi_ta6y cbi_ta8y;
global ach		math5y6m math6y math7y6m math8y math8y6m math12y 	
			read5y6m read6y read7y6m read8y read8y6m read12y;

global varstofactor	home cog ncog ach;
global varstocompare	homefactor cogfactor ncogfactor achfactor;

local numvars : word count $varstocompare ;

# delimit cr

// data
cd $data
use append-abccare_iv, clear

drop if R == 0 & RV == 1

// bootstrap
forvalues b = 0/$bootstraps {

	preserve
	
		if `b' > 0 {
			bsample
		}
		
		// create factors by gender
		foreach f in $varstofactor { 
			qui gen `f'factor = .
			
			forvalues s = 0/1 {
				qui factor  ${`f'} if male == `s'
				qui predict `f'factor_tmp if male == `s'
				qui sum `f'factor_tmp if male == `s'
				qui replace `f'factor_tmp = (`f'factor_tmp - r(mean))/r(sd) if male == `s'
				xtile `f'factor_`s' = `f'factor_tmp, nquantiles($quantiles)
				qui replace `f'factor = `f'factor_`s' if male == `s'
				qui drop `f'factor_tmp `f'factor_`s'
			}
		}
		
		// calculate gender differences
		foreach v in $varstocompare {
			forvalues s = 0/1 {
				qui sum `v' if male == `s'
				matrix `v'`s'_`b' = r(mean)
				
				matrix `v'`s' = (nullmat(`v'`s') \ `v'`s'_`b')
				matrix colnames `v'`s' = `v'`s'
			}
		}
	
	restore
}

// bring to data
local mattoappend
local i = 0

forvalues s = 0/1 {
	foreach v in $varstocompare {
		local i = `i' + 1
		
		if `i' < 2 * `numvars' {
			local mattoappend `mattoappend' `v'`s',
		}
		else {	
			local mattoappend `mattoappend' `v'`s'
		}
	}
}

mat allmeans = (`mattoappend')
clear
svmat allmeans, names(col)
qui gen b = _n

foreach v in $varstocompare {

	forvalues s = 0/1 {
		// point estimate
		qui sum `v'`s' if b == 1
		qui gen point`v'`s' = r(mean)
	}
	
	// male - female
	qui gen gd`v' = `v'1 - `v'0
	
	// point estimate of male - female
	qui gen gdpoint`v' = point`v'1 - point`v'0
	
	// empirical mean of male - female
	qui sum gd`v' if b > 1 & !missing(gd`v'`s')
	qui gen mgd`v' = r(mean)
		
	// demean
	qui gen dgd`v' = gd`v' - mgd`v' if b > 1
		
	// p-values
	qui gen dlower`v' = (dgd`v' < gdpoint`v') 		if !missing(dgd`v')
	qui gen dupper`v' = (dgd`v' > gdpoint`v') 		if !missing(dgd`v')
	qui gen dtwo`v'   = (abs(dgd`v') >= abs(gdpoint`v')) 	if !missing(dgd`v')
		
	foreach p in lower upper two {
		qui sum d`p'`v'
		qui gen p`p'`v' = r(mean)
	}		
}




// graph
