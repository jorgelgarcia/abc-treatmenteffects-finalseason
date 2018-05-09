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
	

	
// calculate treatment effects
foreach c in `categories' {

	foreach v in ``c'' {

		// construct factors
		qui {
		if "`c'" != "all" {
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
		
		// regress
		forvalues s = 0/1 {
			qui reg `v' R if male == `s'
			
			// save beta coefficients
			mat B`v'`s' = e(b)
			mat B`c'`s' = (nullmat(B`c'`s') \ B`v'`s'[1,1])
			
			// extract control-group standard deviation
			qui sum `v' if male == `s' & R == 0
			local `v'sd`s' = r(sd)
			
			if ``v'sd`s'' == 0 {
				di "No variation, `c', `v', male == `s'"
				mat STDB`c'`s' = (nullmat(STDB`c'`s') \ .)
			}
			else if ``v'sd`s'' == . {
				di "Missing sd, `c', `v', male == `s'"
				mat STDB`c'`s' = (nullmat(STDB`c'`s') \ .)
			}
			else {
				local `v'stdb`s' = B`v'`s'[1,1]/``v'sd`s''
				mat STDB`c'`s' = (nullmat(STDB`c'`s') \ ``v'stdb`s'')
			}
		}
			
	}
}

// reshape data
foreach c in `categories' {
	forvalues s = 0/1 {
		mat COMBINE = (nullmat(COMBINE) \ STDB`c'`s')
	}
}


foreach c in `categories' {
	forvalues s = 0/1 {
		foreach v in ``c'' {
		
			mat MALE = (nullmat(MALE) \ `s')
		}
	}
}

mat TODATA = MALE, COMBINE

clear
svmat TODATA

rename TODATA1 male
rename TODATA2 stdb

gen n = _n
gen varname = ""
gen category = ""

local i = 0

foreach c in `categories' {	
	forvalues s = 0/1 {
		foreach v in ``c'' {
		
			local i = `i' + 1
		
			replace varname = "`v'" if n == `i'
			replace category = "`c'" if n == `i'
		}
	}
}

gen flagmissing = 0
replace flagmissing = 1 if varname == "si34y_diab"

// calculate average standardized treatment effect by category
bysort category male: egen avgstdb = mean(stdb)
foreach c in `categories' {
	forvalues s = 0/1 {
		qui sum avgstdb if male == `s' & category == "`c'"
		local avgstdb`c'`s' = r(mean)
		local avgstdb`c'`s' : di %9.3f `avgstdb`c'`s''

	}
}

// rank sum test
foreach c in `categories' {
	qui ranksum stdb if category == "`c'" & flagmissing == 0 , by(male)
	local rsp`c' = 2*(1-normal(abs(r(z))))
	local rsp`c' : di %9.3f `rsp`c''

}

// create table
file open tabfile using "${output}/abccare-category-stdtes-rs.tex", replace write
file write tabfile "\begin{tabular}{l c c c c}" _n
file write tabfile "\toprule" _n
file write tabfile "Category & \# Outcomes & \mc{2}{c}{Average Effect Size} & $ p $ -value  \\" _n
file write tabfile "\cmidrule(lr){3-4}" _n
file write tabfile "		&	&  Female & Male  \\" _n
file write tabfile "\midrule" _n	

foreach c in `categories' {
	local `c'_N : word count ``c''
	
	if "`c'" == "all" {
		file write tabfile "\midrule" _n
	}
	file write tabfile "``c'_name' & $ ``c'_N' $ & $ `avgstdb`c'0' $ & $ `avgstdb`c'1' $ & $ `rsp`c'' $ \\" _n
}

file write tabfile "\bottomrule" _n
file write tabfile "\end{tabular}" _n
file write tabfile "% This file generated by: abccare-cba/scripts/abccare/genderdifferences/abccare-gdiff-stdtes-ranksum.do" _n
file close tabfile

