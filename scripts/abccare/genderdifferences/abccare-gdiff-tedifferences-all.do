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

local name0 female
local name1 male


// data
cd $data
use append-abccare_iv, clear

drop if R == 0 & RV == 1

cd ${scripts}/abccare/genderdifferences
include abccare-112-outcomes
include abccare-112-outcomes-label

// factors
foreach c in `categories' {
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

// treatment effects
forvalues b1 = 0/$bootstraps {
	di "`b1'"
	preserve
	
	if `b1' > 0 {
		bsample
	}
	
	foreach c in `categories' {
		foreach v in ``c'' {
			// by gender
			forvalues s = 0/1 {
				qui sum `v' if male == `s' & R == 0 & apgar1 < . & apgar5 < . & hrabc_index < .
				matrix `v'cmean`s'`b1' = r(mean)
				matrix `name`s''`v'cmean = (nullmat(`name`s''`v'cmean) \ `v'cmean`s'`b1')
				matrix colnames `name`s''`v'cmean = `name`s''`v'cmean
			
				qui reg `v' R if male == `s' 
				
				matrix `v'tab`s' = e(b)
				matrix `v'te`s'`b1' = `v'tab`s'[1,1]
				matrix `name`s''`v'te = (nullmat(`name`s''`v'te) \ `v'te`s'`b1')
				matrix colnames `name`s''`v'te = `name`s''`v'te
			}
		}
	}
	restore
}

// bring to data
di "`all'"
local numvars : word count `all'
local n = 0
foreach c in `categories' {
	foreach v in ``c'' {
		matrix all = (nullmat(all) , male`v'cmean, female`v'cmean, male`v'te, female`v'te)
	}
}

// inference
clear
svmat all, names(col)
qui gen n = _n

foreach c in `categories' {
	
	foreach v in ``c'' {
		foreach t in cmean te {
			local rowname`c' `rowname`c'' `v'`t'
			// rank sum p-values
			qui signrank male`v'`t' = female`v'`t'
			local p`v'`t' = 2 * normprob(-abs(r(z)))
			
			matrix bonf`c'`t' = (nullmat(bonf`c'`t') \ `p`v'`t'')
		
			local p`v'`t' = string(`p`v'`t'', "%9.3fc")
			if "`p`v'`t''" == "0.000" {
				local p`v'`t' "$ < $ 0.001"
			}
		}
	}
	
	matrix colnames bonf`c'cmean = `c'cmean
	matrix rownames bonf`c'cmean = ``c''
	matrix colnames bonf`c'te = `c'te
	matrix rownames bonf`c'te = ``c''

	foreach v in ``c'' {
		foreach t in cmean te {
		
			// difference
			qui gen diff_`t'`v' = male`v'`t' - female`v'`t' if n == 1
			qui sum diff_`t'`v'
			if r(mean) < 1000 {
				local diff_`t'`v' = string(r(mean), "%9.3fc")
			}
			else {
				local diff_`t'`v' = string(r(mean), "%9.0fc")
			}
		
			// point estimates
			forvalues s = 0/1 {
				qui sum `name`s''`v'`t' if n == 1
				if r(mean) < 1000 {
					local po_`t'`v'`name`s'' = string(r(mean), "%9.3fc")
				}
				else {
					local po_`t'`v'`name`s'' = string(r(mean), "%9.0fc")
				}
			}
		}
	}
}

// step down adjustment
foreach c in `categories' {
	//preserve
		
	clear
	matrix fordata = bonf`c'cmean, bonf`c'te
	svmat fordata, names(col)
		
	qui gen n = _n
	global N = _N
	qui gen variable = ""
	forvalues i = 1/$N {
		qui replace variable = "`:word `i' of ``c'''" in `i'
	}
		
	foreach t in cmean te {
		sort `c'`t'
		gen k_`t' = _n
		gen bonf`t' = 0.1/($N + 1 - k_`t')
		gen diff`t' = (`c'`t' > bonf`t')
		
		local mink = $N + 1
		foreach v in ``c'' {
			qui sum diff`t' if variable == "`v'"
			if r(mean) == 1 {
				qui sum k_`t' if variable == "`v'" 
				if r(mean) < `mink' {
					local mink = r(mean)
				}
			}
		}
		if `mink' == 1 {
			foreach v in ``c'' {
				local pb_`v' = 0
			}
		}
		else if `mink' > $N {
			foreach v in ``c'' {
				local pb_`v' = 1
			}
		}
		else {
			gen reject`t' = (k_`t' < `mink')
			foreach v in ``c'' {
				qui sum reject`t' if variable == "`v'"
				local pb_`v' = r(mean)
			}
		}
		foreach v in ``c'' {
			if `pb_`v'' == 1 {
				local p`v'`t' "`p`v'`t'' *"
			}
		}
	}
		
	//restore
}

// make table
foreach c in `categories' {
	file open tabfile using "${output}/abccare-gdiff-treatmenteffects100-`c'.tex", replace write
	file write tabfile "\begin{tabular}{l c c c r c c c r}" _n
	file write tabfile "\toprule" _n
	file write tabfile " \mc{1}{c}{Variable} & \mc{4}{c}{\textbf{Control Mean}} & \mc{4}{c}{\textbf{Treatment Effect}} \\" _n
	file write tabfile "\cmidrule(lr){2-5} \cmidrule(lr){6-9}" _n
	file write tabfile "& Male & Female & Difference & $ p $ -value & Male & Female & Difference & $ p $ -value \\" _n
	file write tabfile "\midrule" _n
	
	foreach v in ``c'' {
		file write tabfile "${name_`v'} & `po_cmean`v'male' & `po_cmean`v'female' & `diff_cmean`v'' & `p`v'cmean' & `po_te`v'male' & `po_te`v'female' & `diff_te`v'' & `p`v'te' \\" _n
	}
	
	file write tabfile "\bottomrule" _n
	file write tabfile "\end{tabular}" _n
	file write tabfile "% This file generated by: abccare-cba/scripts/abccare/genderdifferences/abccare-gdiff-tedifferences-all.do" _n
	file close tabfile
}


