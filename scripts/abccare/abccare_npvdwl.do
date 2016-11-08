/*
Calculate the NPV of the DWL
*/

foreach t in 2 5 8 {

global projects			: env projects
global klmMexico		: env klmMexico
global results 			= "${projects}/abc-treatmenteffects-finalseason/scripts/abccare/cba/ratio_irr/rslt/tables/type`t'"
global sensitivity		= "${projects}/abc-treatmenteffects-finalseason/scripts/abccare/cba/ratio_irr/rslt/sensitivity/"
global output			= "${klmMexico}/abccare/DWL/current"
cd $results

// bring in ratio
// ratio`s' --> bc ratio with DWL of 0.5
foreach s in mean se {
	import delim using "ratio_`s'.csv", clear
	rename v1 sex
	rename v2 ratio`s'
	tempfile ratio_`s'
	save	`ratio_`s''
}

merge 1:1 sex using `ratio_mean', nogen
tempfile ratio
save	`ratio'

// bring in npv
// value`s' --> NPV with DWL of 0.5
import delim using "npv_type`t'.csv", clear
keep if type == "mean" | type == "se"
keep if part == "all"

encode sex, gen(id)
reshape wide value, i(id) j(type) string
drop id part
tempfile npv
save	`npv'

// bring in npv with DWL = 0
// dwl0`s' --> bc ratio with DWL of 0
cd $sensitivity
import delim using "bc_dwl.csv", clear
keep if rate == 0
keep v1 mean se
rename v1 sex
rename mean dwl0mean
rename se dwl0se

// merge together
merge 1:1 sex using `ratio', nogen
merge 1:1 sex using `npv', nogen

// calculate DWL for NPV (mean and se)
foreach s in mean se {
	gen NPV_`s' = (dwl0`s' * value`s') / ratio`s'
	gen DWL_`s' = NPV_`s' - value`s'
}

keep sex value* NPV* DWL*
foreach s in mean se {
	rename value`s' npv_base_`s'
	lab var npv_base_`s' "Base NPV `s' (DWL = 0.5)"
	
	rename NPV_`s'	npv_0_`s'
	lab var npv_0_`s' "NPV `s' with DWL = 0"
	
	rename DWL_`s'	npv_dwl_`s'
	lab var npv_dwl_`s' "Difference `s' between NPV(DWL=0) and NPV(DWL=0.5)"
}

cd $output
save NPV-DWL`t', replace

}
