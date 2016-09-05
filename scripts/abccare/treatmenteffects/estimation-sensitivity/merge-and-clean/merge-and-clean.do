* ---------------------------------------------------------------------------- *
* Cleaning and Computing Standard Errors of the TE results for Sensitivity
* Author: Jessica Yu Kyung Koh
* Date: 2016/09/04
* ---------------------------------------------------------------------------- *

* ------------ *
* Define macro *
* ------------ *
global current 	   : pwd
global result		"${current}/../../rslt-sensitivity"

local genderlist	female


foreach gender in `genderlist' {

	* ---------------------- *
	* Import and clean csv 1 *
	* ---------------------- *
	import delimited "${result}\itt\itt_`gender'_P10.csv", clear

	* Drop unnecessary variables
	drop ddraw itt_noctrl itt_noctrl_p itt_noctrl_n itt_ctrl itt_ctrl_p itt_ctrl_n itt_wctrl_p itt_wctrl_n
	drop if draw == 100

	* Destring variables
	local destringlist 		itt_wctrl   

	foreach var in `destringlist' {
		replace `var' = "" if `var' == "NA"
		destring `var', replace
	}

	* Drop duplicates
	sort rowname controln draw
	quietly by rowname controln draw:  gen dup = cond(_N==1,0,_n)
	drop if dup>1
	drop dup

	save "${current}/output/for_sensitivity_TE_`gender'", replace 


	* ---------------- *
	* Merge with csv 2 *
	* ---------------- *
	import delimited "${result}\matching\matching_`gender'_P0.csv", clear

	* Drop unnecessary variables
	drop ddraw epan_n
	drop if draw == 100
	drop if rowname == "Union{}"

	* Destring variables
	local destringlist 		epan_ipw   
	
	foreach var in `destringlist' {
		replace `var' = "" if `var' == "NA"
		replace `var' = "" if `var' == "NaN"
		destring `var', replace
	}

	* Drop duplicates
	sort rowname controln draw
	quietly by rowname controln draw:  gen dup = cond(_N==1,0,_n)
	
	drop if dup>1 & draw == 0
	
	generate new_draw = .
	replace new_draw = 0 if draw == 0
	replace new_draw = dup + 7*(draw-1) if draw !=0

	drop draw
	rename new_draw draw

	rename epan_ipw	epan_ipw_P0
	
	merge 1:1 rowname controln draw using "${current}/output/for_sensitivity_TE_`gender'"
	drop _merge
	save "${current}/output/for_sensitivity_TE_`gender'", replace 

	* ---------------- *
	* Merge with csv 3 *
	* ---------------- *
	import delimited "${result}\matching\matching_`gender'_P1.csv", clear

	* Drop unnecessary variables
	drop ddraw epan_n
	drop if draw == 100

	* Destring variables
	local destringlist 		epan_ipw   

	foreach var in `destringlist' {
		replace `var' = "" if `var' == "NA"
		replace `var' = "" if `var' == "NaN"
		destring `var', replace
	}

	* Drop duplicates
	sort rowname controln draw
	quietly by rowname controln draw:  gen dup = cond(_N==1,0,_n)
	
	drop if dup>1 & draw == 0
	
	generate new_draw = .
	replace new_draw = 0 if draw == 0
	replace new_draw = dup + 7*(draw-1) if draw !=0

	drop draw
	rename new_draw draw

	
	rename epan_ipw	epan_ipw_P1
	
	merge 1:1 rowname controln draw using "${current}/output/for_sensitivity_TE_`gender'"
	drop _merge
	save "${current}/output/for_sensitivity_TE_`gender'", replace 

	* ------------------------ *
	* Computing standard error *
	* ------------------------ *
	* Group variables by variable and control set
	sort rowname controln draw
	egen group = group(rowname controln)

	* Commpute standard error for each group
	egen sd_itt_wctrl = sd(itt_wctrl), by(group)
	egen sd_epan_P0 = sd(epan_ipw_P0), by(group)
	egen sd_epan_P1 = sd(epan_ipw_P1), by(group)
	
	* Keep the point estimates
	keep if draw == 0
	drop draw
	
	* Save the final file
	label var rowname "Outcome"
	label var controln "Control Set Number"
	label var itt_wctrl "ITT Estimate for Column 2"
	label var sd_itt_wctrl "Standard Error for Column 2"
	label var epan_ipw_P0 "Matching Estimate for Column 5"
	label var sd_epan_P0 "Standard Error for Column 5"
	label var epan_ipw_P1 "Matching Estimate for Column 8"
	label var sd_epan_P1 "Standard Error for Column 8"
	
	drop dup group
	
	order rowname controln itt_wctrl sd_itt_wctrl epan_ipw_P0 sd_epan_P0 epan_ipw_P1 sd_epan_P1 
	save "${current}/output/for_sensitivity_TE_`gender'", replace 
}
