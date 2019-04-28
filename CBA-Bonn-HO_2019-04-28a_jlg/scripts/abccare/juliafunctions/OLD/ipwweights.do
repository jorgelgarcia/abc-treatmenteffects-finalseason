
*=======================================================
* Function to form IPW weights
*=======================================================

capture program drop ipwweights
capture program define ipwweights

version 12
syntax, varsglobal(string) iprefix(string)

tempfile presmall
save `presmall', replace

local keepweights
foreach var in `"${`varsglobal'}"' {

	* form attrition indicator (1 means NOT attrit, 0 means attrit)
	local attr: word 1 of ${w_`var'}
	gen _a_`attr' = !missing(`var')
	gen _a1_`attr' = _a_`attr' * R
	gen _a0_`attr' = _a_`attr' * (1 - R)
	
	* perform logit for treated
	capture logit _a1_${w_`var'}, asis
	if _rc {
		gen `iprefix'`var' = .
		local keepweights `keepweights' `iprefix'`var'
		drop _a_`attr' _a1_`attr' _a0_`attr' 
		continue
	}
	predict Wt, pr
	replace Wt = min(1/Wt, 20) if !missing(Wt)
	egen sum_Att_t = sum((!missing(Wt)) * _a_`attr'	 * R)
	egen sum_Wt_Att_t = sum(Wt * _a_`attr' * R)
	replace Wt = Wt * sum_Att_t / sum_Wt_Att_t if !missing(Wt)
	replace Wt = 1 if missing(Wt)

	* perform logit for untreated
	capture logit _a0_${w_`var'}, asis
	if _rc {
		gen `iprefix'`var' = .
		local keepweights `keepweights' `iprefix'`var'
		drop _a_`attr' _a1_`attr' _a0_`attr' 
		drop Wt 
		drop sum_Att_t sum_Wt_Att_t
		continue
	}
	predict Wc, pr
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
	
}
* keep only the weights and ID variable
keep id `keepweights'
duplicates drop id, force // dropped to avoid merging issues in bootstrap
tempfile ipwweights
save `ipwweights', replace

use `presmall', clear
merge m:1 id using `ipwweights', nogen

end
