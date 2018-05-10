/*
Project: 	Treatment effects
Date:		April 27, 2017

This file:	Means of control group
*/

clear all
set maxvar 30000
set matsize 11000
set more off

// parameters
set seed 1
global bootstraps 25
global maxtries 20
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
	include abccare-112-outcomes

foreach c in age5 age15 age34 iq ach se mlabor parent edu emp health risk crime all {

	gen factor`c' = .
	
	forvalues s = 0/1 {
		local tofactor
		foreach v in ``c'_updated' {
			
			// impute mean for those with missing values
				forvalues r = 0/1 {
					sum `v' if male == `s' & R == `r'
					replace `v' = r(mean) if missing(`v') & male == `s' & R == `r'
				}
			
			qui sum `v' if male == `s'
			cap gen std`v'`s' = (`v' - r(mean))/r(sd)
			local tofactor `tofactor' std`v'`s'
		}
		cap factor `tofactor'
		if !_rc {
			cap predict `c'_`s' if male == `s'
			if _rc {
				gen `c'_`s' = . if male == `s'
			}
		}
		replace factor`c' = `c'_`s' if male == `s'
		drop `c'_`s'
	}
}


keep id R RV male dc_mo_pre factor*
cd $data
saveold abccare-factors-R-inputold, version(12) replace