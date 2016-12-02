/*
Project :       	ABC CBA
Description:    	Tax from income
This version: 	 	November 18, 2016
This .do file: 		Anna Ziff
This project : 		CBA Team

Note :				Download taxsim9: http://users.nber.org/~taxsim/stata.html
*/

global erc			: 	env erc
global projects		: 	env projects
global klmshare		: 	env klmshare
global klmmexico	: 	env klmMexico
global googledrive	: 	env googledrive

global inc_data 	=	"${klmmexico}/abccare/income_projections/current/"
global abc_data		= 	"${klmshare}/Data_Central/Abecedarian/data/ABC-CARE/base"
global output		= 	"${klmmexico}/abccare/DWL"

cd $abc_data
use append-abccare, clear
drop if RV == 1 & R == 0
local keepvars 	id birthyear R male si21y_mstat_bin si30y_mstat_bin si30y_state ///
				num_child_home numchild_age21 si21y_inc_labor si30y_inc_labor
keep `keepvars'

rename si21y_inc_labor inc_21
rename si30y_inc_labor inc_30

tempfile abc_data
save	`abc_data'


cd $inc_data
import delim using "labor_proj_combined_pset1_mset1_pooled.csv", clear

// rename variables
forvalues i = 3/10 {
	local a = `i' + 19
	rename v`i' c`a'
}
forvalues i = 11/47 {
	local a = `i' + 20 
	rename v`i' c`a'
}


/*
// collapse
forvalues a = 22/29 {
	bysort id: egen inc_`a' = mean(c`a')
}
forvalues a = 31/67 {
	bysort id: egen inc_`a' = mean(c`a')
}

keep if adraw == 0
drop adraw c*
*/
merge m:1 id using `abc_data'
drop if _merge == 2
drop _merge

rename inc_21 c21
rename inc_30 c30

sort adraw id
gen N = _n

reshape long c, i(N) j(age)

// year
// SETTING YEAR TO 2015 for all ages
gen year = 2015

// numbers for states. assume NC if no state given
gen state = .
replace state = 33 	if si30y_state == "NC" | si30y_state == ""
replace state = 1 	if si30y_state == "AL"
replace state = 5 	if si30y_state == "CA"
replace state = 6 	if si30y_state == "CO"
replace state = 10 	if si30y_state == "GA"
replace state = 14 	if si30y_state == "IN"
replace state = 17 	if si30y_state == "KY"
replace state = 18 	if si30y_state == "LA"
replace state = 20 	if si30y_state == "MD"
replace state = 30 	if si30y_state == "NJ"
replace state = 32 	if si30y_state == "NY"
replace state = 40 	if si30y_state == "SC" 
replace state = 46 	if si30y_state == "VA"
replace state = 47 	if si30y_state == "WA"

// marital status. have to assume single and that income is individual
// given there is no information on the spouse's income
gen mstat = 1
//replace mstat = si21y_mstat_bin if age < 30
//replace mstat = si30y_mstat_bin if age >= 30
//recode mstat (1=2) (0=1)

// children
gen depchild = .
replace depchild = numchild_age21 if age < 30
replace depchild = num_child_home if age >= 30

//agex
gen agex = age*100

// pwages
rename c pwages

// only keep relevant variables. Dropping depchild because produces many missings
keep age adraw id pwages year state mstat /*depchild*/ agex

// calculate taxes
taxsim9, replace

// fill for years taxsim isn't available
foreach t in frate srate ficar {
	//sort id
	//by id: ipolate `t' pwages, gen(`t'_exp) epolate
	//replace `t' = `t'_exp if `t' == .
	//drop `t'_exp
	
	gen `t'_paid = (`t'/100) * pwages
}


gen tax = frate_paid + srate_paid + ficar_paid if frate_paid < . & srate_paid < . & frate_paid < .
keep tax age adraw id

// drop negative income. Not applicable here.
drop if pwages < 0

sort id adraw
gen N = _n
reshape wide tax, i(N) j(age)

drop N 
order adraw id, first

cd $output
export delim using "tax_proj_pooled.csv", replace
