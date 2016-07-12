*=======================================================
* Function to form linear-probability IPW weights
*=======================================================

capture program drop lipwweights
capture program define lipwweights

version 12
syntax, varsglobal(string) iprefix(string)

tempfile presmall
save `presmall', replace

local discretized m_iq0y m_ed0y m_age0y hrabc_index apgar1 apgar5 has_relatives hh_sibs0y //cohort

local keepweights
foreach var in `"${`varsglobal'}"' {

	* form attrition indicator (1 means NOT attrit, 0 means attrit)
	local attr: word 1 of ${w_`var'}
	gen _a_`attr' = !missing(`var')
	gen _a1_`attr' = _a_`attr' * R
	gen _a0_`attr' = _a_`attr' * (1 - R)
	
	* switch out variables for discretized ones if necessary
	forvalues i = 1/4 {
		local ipwvar: word `i' of ${w_`var'}
		if `i' == 1 local new_ipw
		else {
			local disc: list posof "`ipwvar'" in discretized
			if `disc' > 0 local new_ipw `new_ipw' _d_`ipwvar'
			else local new_ipw `new_ipw' `ipwvar'
		}	
	}
	
	
	* perform linear probability model for treated
	egen _ipwg_ = group(`new_ipw')
	capture regress _a1_`attr' i._ipwg_
	if _rc {
		gen `iprefix'`var' = .
		local keepweights `keepweights' `iprefix'`var'
		drop _a_`attr' _a1_`attr' _a0_`attr' 
		drop _ipwg_
		continue
	}
	predict Wt, xb

	replace Wt = round(Wt, 0.1) if Wt < 0.0001
	replace Wt = min(1/Wt, 20) if !missing(Wt)
	egen sum_Att_t = sum((!missing(Wt)) * _a_`attr'	 * R)
	egen sum_Wt_Att_t = sum(Wt * _a_`attr' * R)
	replace Wt = Wt * sum_Att_t / sum_Wt_Att_t if !missing(Wt)
	replace Wt = 1 if missing(Wt)

	* perform linear probability for untreated
	capture regress _a0_`attr' i._ipwg_
	if _rc {
		gen `iprefix'`var' = .
		local keepweights `keepweights' `iprefix'`var'
		drop _a_`attr' _a1_`attr' _a0_`attr' 
		drop Wt 
		drop sum_Att_t sum_Wt_Att_t
		drop _ipwg_
		continue
	}

	predict Wc, xb

	replace Wc = round(Wc, 0.1) if Wc < 0.0001
	replace Wc = min(1/Wc, 20) if !missing(Wc)
	egen sum_Att_c = sum((!missing(Wc)) * _a_`attr' * (1-R))
	egen sum_Wc_Att_c = sum(Wc * _a_`attr' * (1-R))
	replace Wc = Wc * sum_Att_c / sum_Wc_Att_c if !missing(Wc)
	replace Wc = 1 if missing(Wc)
	
	* generate weights
	gen `iprefix'`var' = R * Wt + (1 - R) * Wc
	local keepweights `keepweights' `iprefix'`var'
	
	* drop attrition variables 
	drop _a_`attr' _a1_`attr' _a0_`attr' 
	drop Wt Wc 
	drop sum_Att_t sum_Wt_Att_t sum_Att_c sum_Wc_Att_c 
	drop _ipwg_
	
}
* keep only the weights and ID variable
*keep id `keepweights'
duplicates drop id, force // dropped to avoid merging issues in bootstrap
tempfile ipwweights
save `ipwweights', replace

use `presmall', clear
merge m:1 id using `ipwweights', nogen

end

