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
				part == "crimeprivate" |
				part == "health" |
				part == "health_private" |
				part == "inc_labor" |
				part == "inc_parent" |
				part == "qaly" |
				part == "transfer";
	# delimit cr

	foreach sex in f m p {
		foreach stat in mean se {
			preserve
				keep if sex == "`sex'" & type == "`stat'"
				sxpose, clear force
				
				drop if _var1 == "`sex'" | _var1 == "`stat'"
				forval i = 1/10 {
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
	
	forvalues i = 1/13 {
		gen v`i' = "&"
	}
	gen v14 = "\\"
	bysort sex: gen N = _n
	
	foreach var in costs cc crimepublic edu m_ed health_public diclaim inc_trans_pub ssclaim ssiclaim{
		destring(`var'), replace
		format `var' %9.0fc
	}
	
	replace sex = "Female" 	if sex == "f"
	replace sex = "Male" 	if sex == "m"
	replace sex = "Pooled" 	if sex == "p"
	replace sex = ""		if stat == "se"
	
	local subtotal costs cc crimepublic edu m_ed health_public diclaim inc_trans_pub ssclaim ssiclaim
	egen subtotal = rowtotal(`subtotal')
	
	gen dwl = subtotal/2
	
	local total subtotal dwl
	egen total = rowtotal(`total')
	
	foreach var in subtotal dwl total {
		replace `var' = . if N ==2
	}
	
	format subtotal %9.0fc
	format total %9.0fc
	format dwl %9.0fc
	order sex v1 costs v2 cc v3 crimepublic v4 edu v5 m_ed v6 health_public v7 inc_trans_pub v8 diclaim v9 ssclaim v10 ssiclaim v11 subtotal v12 dwl v13 total v14
	drop stat
	
	save tmp_dwl`t', replace
}
