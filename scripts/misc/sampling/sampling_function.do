/*
Project		ABC and CARE CBA
Date 		June 30, 2016
Author		Joshua Shea
Description	This .do file generates the bootstraps for the baseline tables
		(bootstrapping in python is kind annoying, doesn't include 
		clustering and strata)
*/

capture program drop sampler
capture program define sampler

version 12.0
syntax, breps(integer) [program(string) cluster(varlist) strata(varlist) id(string)]

if "`id'" == "" local idvar id
else local idvar `id'

* save the original file with everything you need
if "`program'" != "" {
	local pvar abc
}
foreach v in `idvar' `cluster' `strata' `pvar' {
	confirm variable `v'
}

* keep the program you want
if "`program'" == "abc" keep if abc == 1
if "`program'" == "care" keep if abc == 0

* configure bootstrap options
if "`cluster'" != "" local coption cluster(`cluster')
if "`strata'" != "" local soption strata(`strata')

* save original IDs
tempfile orig
save `orig'

preserve
keep `idvar'
rename `idvar' draw0
tempfile bootstraps
save `bootstraps'
restore

* begin bootstrapping
local breploop = `breps' - 1 // This extra line is just to deal with Python
forvalues b = 1/`breploop' {
	preserve
	use `orig', clear
	bsample, `coption' `soption'
	sort abc id 
	keep id
	rename id draw`b'
	merge 1:1 _n using `bootstraps', nogen
	save `bootstraps', replace
	restore
}

use `bootstraps', clear
order draw*, sequential

end
