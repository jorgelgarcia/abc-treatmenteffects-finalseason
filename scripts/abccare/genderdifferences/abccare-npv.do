/* 
Project:		Mediation
Author:			Anna Ziff (aziff@uchicago.edu)
			Jorge Luis Garcia (jorgelgarcia@uchicago.edu)
Original date:		January 7, 2016
This file:		Brings in NPV data
Output:			Data with NPV merged
*/

// macros
global abccare_laborincome      = "${klmmexico}/abccare/income_projections/current/"
global abccare_health           = "${klmshare}/Data_Central/Abecedarian/data/ABC-CARE/extensions/fam-merge/"
global abccare_batch            = "${klmshare}/Data_Central/Abecedarian/data/ABC-CARE/extensions/outcomes_ate/"

// income
cd $abccare_laborincome
insheet using labor_proj_combined_pset1_mset1_male.csv, clear
gen male = 1
tempfile male
save "`male'", replace

insheet using labor_proj_combined_pset1_mset1_female.csv, clear
gen male = 0 
tempfile female 
save "`female'", replace

append using "`male'"

// discount
foreach num of numlist 23(1)67 {
	replace v`num' = v`num' / ((1 + $discount )^`num')
}

egen income = rowtotal(v*), missing
keep adraw id income male

// merge treatment indicator
cd $abccare_output
merge m:1 id using abccare-mediation, keepusing(R)
keep if _merge == 3
drop _merge
gen treatmale = R*male

tempfile npv_income
save   "`npv_income'", replace

// health
cd $abccare_health
use abc-fam-merge.dta, clear

// discount
foreach var in diclaim qaly ssclaim ssiclaim health_private health_public {
	
	foreach num of numlist 8(1)122 {
		if "`var'" == "qaly" {
			replace `var'`num' = `var'`num' * 150000 // cost of a statistical life
		}
		capture replace `var'`num' = (`var'`num')/((1 + $discount)^`num')
	}
	egen `var' = rowtotal(`var'*), missing
}

egen health_costs = rowtotal(health_private health_public), missing
keep id adraw health_costs qaly

tempfile npv_health
save   "`npv_health'", replace

// so called batch
cd $abccare_batch
use outcomes_ate.dta, clear

// discount
foreach var in ip_p_inc public_crime private_crime {
	foreach num of numlist 0(1)50 {
		capture replace `var'`num' = (`var'`num')/((1 + $discount)^`num')
	}
	egen `var' = rowtotal(`var'*), missing
}
egen crime = rowtotal(public_crime private_crime), missing
keep id crime ip_p_inc

tempfile npv_batch 
gen adraw = 0
save   "`npv_batch'", replace

// merge all together
use  "`npv_income'"
merge 1:1 id adraw using  "`npv_health'"
keep if _merge == 3
drop _merge

merge 1:1 id adraw using "`npv_batch'"
keep if _merge != 2
drop _merge


