clear all
set maxvar 32000

* change directory
global projects:	env projects
global projections	"$projects/abc-treatmenteffects-finalseason/scripts/abccare/cba/income/rslt/projections"
global abccare		"$projects/abc-treatmenteffects-finalseason/data/abccare/extensions/cba-iv"

* bring in projections

cd $projections

foreach sex in female male pooled {
	foreach inc in labor transfer {
		insheet using `inc'_proj_`sex'.csv, comma names clear
		
		* deal with missing ID for USC
		replace id = .x if id == 9999
		
		* rename variables
		foreach var of varlist v* {
			local age : var label `var'
			rename `var' age`age'
		}
		rename adraw bootstrap
		
		* bring in age 21 and 30 variables
		if "`inc'" == "labor" {
			merge m:1 id using "$abccare/append-abccare_iv.dta", keepusing(si21y_inc_labor si30y_inc_labor) keep(1 3) nogen
			rename si21y_inc_labor age21
			rename si30y_inc_labor age30
			order age21, before(age22)
			order age30, before(age31)
		}
		if "`inc'" == "transfer" {
			merge m:1 id using "$abccare/append-abccare_iv.dta", keepusing(si21y_inc_trans_pub si30y_inc_trans_pub) keep(1 3) nogen
			rename si21y_inc_trans_pub age21
			rename si30y_inc_trans_pub age30
			order age21, before(age22)
			order age30, before(age31)
		}
		
		sort id bootstrap
		save `inc'_proj_`sex'.dta, replace	
	}
}


