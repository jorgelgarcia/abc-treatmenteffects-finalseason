/*
Project :       ABC CBA
Description:    obtains all estimates to collate sensitivity of IRR and B/C
*This version:  April 18, 2016
*This .do file: Jorge L. Garcia
*This project : CBA Team
*/

global erc			: env erc
global projects		: env projects
global klmshare		:  env klmshare
global klmmexico	: env klmMexico
global googledrive	: env googledrive

global dwl5 = "${klmMexico}/abccare/DWL/current"


foreach t in 2 5 8 {

	cd $projects
	cd abc-treatmenteffects-finalseason
	cd scripts/abccare/cba/ratio_irr/rslt/tables

	import delim using "npv_type`t'_dwl0_dr0.csv", clear
	
	# delimit ;
		keep if type == "mean" | 
				type == "se";
				
		drop if part == "all" |
				part == "crime" |
				part == "crimepublic" |
				part == "diclaim" |
				part == "health" |
				part == "health_private" |
				part == "inc_labor" |
				part == "inc_parent" |
				part == "inc_trans_pub" |
				part == "m_ed" |
				part == "qaly" |
				part == "ssclaim" |
				part == "ssiclaim" |
				part == "ssclaim" |
				part == "transfer";
	# delimit cr

	foreach sex in f m p {
		foreach stat in mean se {
			preserve
				keep if sex == "`sex'" & type == "`stat'"
				sxpose, clear force
				
				drop if _var1 == "`sex'" | _var1 == "`stat'"
				forval i = 1/4 {
					rename _var`i' `= _var`i'[1]'
				}
				drop if health_public == "health_public"
				
				gen stat = "`stat'"
				gen sex = "`sex'"
				
				tempfile `sex'`stat'
				save ``sex'`stat''
				
			restore
		}
	}
	
	use `fmean', clear
	append using `fse'
	append using `mmean'
	append using `mse'
	append using `pmean'
	append using `pse'

	order stat sex, first
	
	tempfile part`t'
	save `part`t''
	
	import delim using "npv_type`t'_ped.csv", clear
	# delimit ;
		keep if type == "mean" | 
				type == "se";
				
		keep if part == "crimepublic" |
				part == "edu" |
				part == "m_ed"; 
	# delimit cr
	
		foreach sex in f m p {
		foreach stat in mean se {
			preserve
				keep if sex == "`sex'" & type == "`stat'"
				sxpose, clear force
				
				drop if _var1 == "`sex'" | _var1 == "`stat'"
				forval i = 1/3 {
					rename _var`i' `= _var`i'[1]'
				}
				drop if crimepublic == "crimepublic"
				
				gen stat = "`stat'"
				gen sex = "`sex'"
				
				tempfile `sex'`stat'
				save ``sex'`stat''
				
			restore
		}
	}
	
	use `fmean', clear
	append using `fse'
	append using `mmean'
	append using `mse'
	append using `pmean'
	append using `pse'
	
	order stat sex, first
	
	merge 1:1 sex stat using `part`t'', nogen
	aorder
	order stat sex, first
	
	drop stat
	forvalues i = 1/8 {
		gen v`i' = "&"
	}
	gen v9 = "\\"
	
	foreach var in costs cc crimepublic edu m_ed health_public {
		destring(`var'), replace
		format `var' %9.0fc
	}
	bysort sex: gen stat = _n
	tempfile components`t'
	save `components`t''
	
	cd $dwl5
	use NPV-DWL`t', clear
	keep sex npv_dwl_*
	rename npv_dwl_mean npv_dwl_1
	rename npv_dwl_se npv_dwl_2
	reshape long npv_dwl_, i(sex) j(stat)
	
	merge 1:1 sex stat using `components`t'', nogen
	
	replace sex = "Female" 	if sex == "f"
	replace sex = "Male" 	if sex == "m"
	replace sex = "Pooled" 	if sex == "p"
	rename npv_dwl_ DWL
	
	local to_sum costs crimepublic edu m_ed health_public DWL
	egen Total = rowtotal(`to_sum')
	format Total %9.0fc
	format DWL %9.0fc
	order sex v1 costs v2 cc v3 crimepublic v4 edu v5 m_ed v6 health_public v7 DWL v8 Total v9
	drop stat
	
	save tmp_dwl`t', replace
}
