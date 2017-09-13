/*
Project: 	Treatment effects
Date:		September 13, 2017

This file:	abccare-gdiff-gaps-ranksign FOR PERRY
*/

clear all
set more off
set maxvar 30000
set matsize 11000

// parameters
set seed 1
global bootstraps 10
global quantiles 30

// macros
global projects		: env projects
global klmshare		: env klmshare
global klmmexico	: env klmMexico


**********
* PERRY *
*********

// filepaths
global data	   	= "$klmshare/Data_Central/data-repos-old/perry/base"
global scripts    	= "$projects/abccare-cba/scripts/"
global output      	= "$projects/abccare-cba/output/"

// data
cd $data
use perry-base, clear

// variables
cd ${scripts}/abccare/genderdifferences
qui include perry-112-outcomes


// create factor variables
foreach c in `categories' {
	if "`c'" != "all" {
		foreach v in ``c'' {
	
		
			if substr("`v'",1,6) == "factor" {
				gen `v' = .
			}
		
			forvalues s = 0/1 {
				local tofactor
				if substr("`v'",1,6) == "factor" {
					foreach v2 in ``v'' {
						sum `v2'
					gen std`v2'`s' = (`v2' - r(mean))/r(sd)
						local tofactor `tofactor' std`v2'`s'
					}
					cap factor `tofactor'
					if !_rc {
						cap predict `v'`s'
						if _rc {
							gen `v'`s' = .
						}
					}
					replace `v' = `v'`s' if male == `s'
				}
			}
		}
	}
}

forvalues b = 0/$bootstraps {
	di "`b'"
	preserve
	
	if `b' > 0 {
		bsample
	}
	
	foreach c in `categories' {
		
		local counter0 = 0			// use to keep track of number Y_m - Y_f > 0
		local counter1 = 0
		local numvars : word count ``c'' 	// number of variables
		
		foreach v in ``c'' {
			forvalues s = 0/1 {
				qui sum `v' if male == `s' & treatment == 0  
				local b`v'`s'`b'_R0 = r(mean)
				qui sum `v' if male == `s' & treatment == 1
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
local numcats : word count `categories'

foreach c in `categories' {
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


di "`formatrix'"

matrix all = `formatrix'


clear
svmat all, names(col)
gen draw = _n


// inference
foreach c in `categories' {
	signrank `c'1 = `c'0
	local p`c' = 2 * normprob(-abs(r(z)))
	if `p`c'' <= 0.101 {
		local sig = 1
	}
	else {
		local sig = 0
	}
	
	local p`c' = string(`p`c'', "9.3f")

	qui gen `c'_0_1 = `c'1 - `c'0
	sum `c'_0_1 if draw == 1
	local `c'_0_1 = string(r(mean), "%9.3f")
	
	if `sig' == 1 {
		local `c'_0_1 "\textbf{``c'_0_1'}"
	}
	
	// test if =50
	forvalues r = 0/1 {
		sum `c'`r' if draw == 1
		gen point`c'`r' = r(mean)
		
		sum `c'`r' if draw > 1
		gen emp`c'`r' = r(mean)
		
		gen dm`c'`r' = `c'`r' - emp`c'`r' + 0.5
		
		gen diff1`c'`r' = (dm`c'`r' < point`c'`r') if draw > 1
		gen diff2`c'`r' = (dm`c'`r' > point`c'`r') if draw > 1
		sum diff1`c'`r'
		local p1`c'`r' = r(mean)
		sum diff2`c'`r'
		local p2`c'`r' = r(mean)
	
		sum `c'`r' if draw == 1
		local `c'`r' = r(mean)
		if `p1`c'`r'' <= 0.101 | `p2`c'`r'' <= 0.101 {
			local sig50 = 1
		}
		else {
			local sig50 = 0
		}
		local `c'`r' = string(``c'`r'', "%9.3f")
		if `sig50' == 1 {
			local `c'`r' "\textbf{``c'`r''}"
		}
	}
	
}

rename * perry*

tempfile perry
save	`perry'

********
* ABC *
*******

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
include abccare-outcomes
include abccare-reverse
include abccare-112-outcomes


// create factor variables
foreach c in `categories' {
	if "`c'" != "all" {
		foreach v in ``c'' {
	
		
			if substr("`v'",1,6) == "factor" {
				gen `v' = .
			}
		
			forvalues s = 0/1 {
				local tofactor
				if substr("`v'",1,6) == "factor" {
					foreach v2 in ``v'' {
						sum `v2'
					gen std`v2'`s' = (`v2' - r(mean))/r(sd)
						local tofactor `tofactor' std`v2'`s'
					}
					cap factor `tofactor'
					if !_rc {
						cap predict `v'`s'
						if _rc {
							gen `v'`s' = .
						}
					}
					replace `v' = `v'`s' if male == `s'
				}
			}
		}
	}
}

forvalues b = 0/$bootstraps {
	di "`b'"
	preserve
	
	if `b' > 0 {
		bsample
	}
	
	foreach c in `categories' {
		local counter0 = 0			// use to keep track of number Y_m - Y_f > 0
		local counter1 = 0
		local numvars : word count ``c'' 	// number of variables
	
		foreach v in ``c'' {
			
			forvalues s = 0/1 {
				sum `v' if male == `s' & R == 0  //& dc_mo_pre == 0 //dc_mo_pre > 0 & dc_mo_pre != . //
				local b`v'`s'`b'_R0 = r(mean)
				sum `v' if male == `s' & R == 1
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
local numcats : word count `categories'

foreach c in `categories' {
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
foreach c in `categories' {
	signrank `c'1 = `c'0
	local p`c' = 2 * normprob(-abs(r(z)))
	if `p`c'' <= 0.101 {
		local sig = 1
	}
	else {
		local sig = 0
	}
	
	local p`c' = string(`p`c'', "9.3f")

	qui gen `c'_0_1 = `c'1 - `c'0
	sum `c'_0_1 if draw == 1
	local `c'_0_1 = string(r(mean), "%9.3f")
	
	if `sig' == 1 {
		local `c'_0_1 "\textbf{``c'_0_1'}"
	}
	
	// test if =50
	forvalues r = 0/1 {
		sum `c'`r' if draw == 1
		gen point`c'`r' = r(mean)
		
		sum `c'`r' if draw > 1
		gen emp`c'`r' = r(mean)
		
		gen dm`c'`r' = `c'`r' - emp`c'`r' + 0.5
		
		gen diff1`c'`r' = (dm`c'`r' < point`c'`r') if draw > 1
		gen diff2`c'`r' = (dm`c'`r' > point`c'`r') if draw > 1
		sum diff1`c'`r'
		local p1`c'`r' = r(mean)
		sum diff2`c'`r'
		local p2`c'`r' = r(mean)
	
		sum `c'`r' if draw == 1
		local `c'`r' = r(mean)
		if `p1`c'`r'' <= 0.101 | `p2`c'`r'' <= 0.101 {
			local sig50 = 1
		}
		else {
			local sig50 = 0
		}
		local `c'`r' = string(``c'`r'', "%9.3f")
		if `sig50' == 1 {
			local `c'`r' "\textbf{``c'`r''}"
		}
	}
	
}

rename * abc*
