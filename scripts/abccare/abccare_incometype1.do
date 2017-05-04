/* 
Project:		ABC CBA
Author:			Anna Ziff
Original date:	11/26/16
This file: 		NPV of income type 1 (sensitivity)
*/

// macros
global klmshare		: env klmshare
global klmMexico 	: env klmMexico
global projects 	: env projects

global income_data 	= "${projects}/abc-treatmenteffects-finalseason/scripts/abccare/cba/income/rslt/projections"
global save_data 	= "${klmMexico}/abccare/NPV/current"
//global abc_data		= "${klmshare}/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv"
global abc_data			= "${projects}/abc-treatmenteffects-finalseason/data/abccare/extensions/cba-iv"

// get ABC/CARE data from klmshare
cd $abc_data
use append-abccare_iv, clear

drop if R == 0 & RV == 1
keep id male R si21y_inc_labor si30y_inc_labor

tempfile abcdata
save	`abcdata'

// get income data 
cd $income_data

foreach sex in male /*female pooled*/ {
	import delim using "labor_proj_`sex'.csv", clear
	merge m:1 id using `abcdata'
	keep if _merge == 3
	
	// correct age
	local age = 22
	forvalues i = 3/10 {
		rename v`i' c`age'
		local age = `age' + 1
	}
	local age = 31
	forvalues i = 11/47 {
		rename v`i' c`age'
		local age = `age' + 1
	}
	rename si21y_inc_labor c21
	rename si30y_inc_labor c30
	
	// discount
	local varlist
	forvalues a = 21/67 {
		gen D`a' = c`a'/(1.03^`a')
		local varlist `varlist' D`a'
	}
	
	keep id D* male R adraw
	sort adraw id male D* 
	// sum life-cycle income by id and bootstrap
	egen labor = rowtotal(`varlist'), missing

	// ITT by bootstrap
	collapse  labor, by(adraw R)
	gen ITT = .
	forvalues adraw = 0/99 {
		qui sum labor if R == 0 & adraw == `adraw'
		local R0 = r(mean)
		qui sum labor if R == 1 & adraw == `adraw'
		local R1 = r(mean)
		
		replace ITT = `R1' - `R0' if adraw == `adraw'
		
	}
	asd
	di "sex: `sex'"
	sum ITT
	drop if R == 1
	drop if adraw == .

	//get mean and sd of bootstraps by R and male
	collapse (mean) labor_mean=ITT (sd) labor_sd=ITT
	gen sex = "`sex'"
	
	tempfile sex`sex'
	save	`sex`sex''
}

append using `sexmale'
append using `sexfemale'



