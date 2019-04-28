* collect variable names to estimate effects for
cd "${base}/analysis/income/code"
insheet using "outcomes.csv", comma clear names
levelsof variable, local(yvars)
global yvars `yvars'

* collect variable names we need IPW for
levelsof variable if ipw_var!="", local(ipwvars)
global ipwvars `ipwvars'
foreach var in `ipwvars'{
	local _w_`var'
	levelsof ipw_var if variable == "`var'", local(ivar1)
	local ivar2 : word 1 of `ivar1'
	forvalues i = 1/3 {
		levelsof ipw_pooled`i' if variable == "`var'", local(svar1)
		local svar2 : word 1 of `svar1'
		local _w_`var' `_w_`var'' `svar2'
	}
	global w_`var' `ivar2' `_w_`var''
}


*------------------------------------

cd "${results}"

* bring in pooled results
insheet using "labor_proj_pooled.csv", names clear
replace id = "9999" if id == "nan"
destring id, replace
foreach var of varlist v* {
	local age : var label `var'
	rename `var' c`age'_pooled
}
tempfile projections
save `projections'

* bring in male results
insheet using "labor_proj_male.csv", names clear
foreach var of varlist v* {
	local age : var label `var'
	rename `var' c`age'_male
}
merge 1:1 id adraw using `projections', nogen
save `projections', replace

* bring in female results
insheet using "labor_proj_female.csv", names clear
replace id = "9999" if id == "nan"
destring id, replace
foreach var of varlist v* {
	local age : var label `var'
	rename `var' c`age'_female
}
merge 1:1 id adraw using `projections', nogen
save `projections', replace

*------------------------------------

* merge in age 21 and 30 income
use "${abc}/append-abccare_iv", clear
drop if R==0 & RV==1

keep id R P family male si21y_inc_labor si30y_inc_labor $controls $ipwvars_all
replace id = 9999 if missing(id)

merge 1:m id using `projections', nogen

* organize data
rename si21y_inc_labor c21
rename si30y_inc_labor c30
*order c21, before(c22)
*order c30, after(c29)
sort adraw id

* deal with deaths
if $deaths == 1 {
	local id74age	0
	local id9999age	0
	local id914age	1
	local id99age	4
	local id909age	30
	local id87age	29
	local id920age	38
	local id951age	37
	local id117age	38
	local id947age	38
	local id943age	40
	
	foreach id in 74 9999 914 99 909 87 920 951 117 947 943 {
		quietly sum male if id == `id'
		if r(mean) == 1 local sex male
		if r(mean) == 0 local sex female
		forvalues age = 21/67 {
			if `age' > `id`id'age' {
				if `age' == 21 | `age' == 30 {
					di as error "Dealing with deaths: `id' at age `age'"
					replace c`age' = 0 if id == `id' 
				}
				else{
					di as error "Dealing with deaths: `id' at age `age'"
					replace c`age'_`sex' = 0 if id == `id' 
					replace c`age'_pooled = 0 if id == `id' 
				}
			}
		}
	}
}

* generate dummies if necessary 
foreach var in $ipwvars_all {
	if "`var'"!="cohort" {
		levelsof `var', local(lv)
		local lvn: word count `lv'
		if `lvn' > 2 {
			sum `var', detail
			gen _d_`var' = `var' > r(p50)
			replace _d_`var' = . if missing(`var')
		}
	}
	else {
		gen _d_`var' = `var'
	}
}


cd "${dofiles}"
