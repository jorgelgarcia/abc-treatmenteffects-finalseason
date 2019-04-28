* collect variable names to estimate effects for
cd "${base}/${component}"
insheet using "outcomes.csv", comma clear names
levelsof variable, local(yvars)
global yvars `yvars'

* collect variable names we need IPW for
tostring ipw_var, replace
replace ipw_var = "" if ipw_var == "."
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

* bring in USC projections
use "${data}/abc-fam-merge", clear
*drop if R==0 & RV==1

*keep id R P male family $controls $ipwvars_all
replace id = 9999 if missing(id)


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
		forvalues age = 8/79 {
			if `age' > `id`id'age' {
				di as error "Dealing with deaths: `id' at age `age'"
				replace health_private_surv`age' = 0 if id == `id' 
				replace health_public_surv`age' = 0 if id == `id' 
			}
		}
		forvalues age = 30/79 {
			if `age' > `id`id'age' {
				di as error "Dealing with deaths: `id' at age `age'"
				replace diclaim_surv`age' = 0 if id == `id' 
				replace ssiclaim_surv`age' = 0 if id == `id' 
				replace ssclaim_surv`age' = 0 if id == `id' 
				replace qaly_surv`age' = 0 if id == `id' 
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
