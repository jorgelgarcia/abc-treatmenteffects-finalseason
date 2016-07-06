clear all
set more off
set maxvar 32000
version 12

local filedir: pwd

// little command for stringing up the point estimates
capture program drop pointstring
program define pointstring

syntax varlist

foreach varname in `varlist' {
	capture tostring `varname', replace
	if _rc {
		gen `varname'_s = string(`varname')
		drop `varname'
		rename `varname'_s `varname'
	}
}
end

	
/* TEMP FILE PATH FOR JOSH*/
cd "/home/jkcshea/Documents/cehd/projects/abc-treatmenteffects-finalseason/scripts/abccare/cba/ratio_irr/sensitivity"

// Check file path
local filedir: pwd
if strpos("`filedir'", "cba")==0 &  strpos("`filedir'", "ratio_irr")==0 & strpos("`filedir'", "sensitivity")==0 {
	di as error "ERROR: Must run file from its directory."
	exit 101
}

// output file path
global csvs	../rslt/sensitivity/
global output	../../../../../AppOutput/Sensitivity

// change into directory

cd "$csvs"

foreach stat in point se pval {

	// by component, b/c ratio
	insheet using bc_factors.csv, names clear
	replace lb = "" if strpos(lb, "inf")
	replace ub = "" if strpos(ub, "inf")
	destring lb ub, replace
	gen sig = pval < 0.10
	gen keep = 0
	replace keep = 1 if rate == 0
	replace keep = 1 if rate == 1 & part == "costs"
	replace part = "base" if keep == 1 & part == "costs" & rate == 1
	keep if keep == 1
	drop if part == "costs"
	gen type = "bcr"
	keep sex `stat' part sig type
	destring `stat', replace
	tempfile bcrfactor
	save `bcrfactor', replace

	// by component, irr
	insheet using irr_factors.csv, names clear
	gen sig = pval < 0.10
	gen keep = 0
	replace keep = 1 if rate == 0
	replace keep = 1 if rate == 1 & part == "costs"
	replace part = "base" if keep == 1 & part == "costs" & rate == 1
	keep if keep == 1
	drop if part == "costs"
	gen type = "irr"
	keep sex part `stat' sig type
	destring `stat', replace
	tempfile irrfactor
	save `irrfactor', replace

	// DWL, b/c ratio
	insheet using bc_dwl.csv, names clear
	gen part = "dwl"
	gen sig = pval < 0.10
	keep if rate == 0
	drop if part == "costs"
	gen type = "bcr"
	keep sex `stat' part sig type
	destring `stat', replace
	tempfile bcrdwl
	save `bcrdwl', replace

	// DWL, irr
	insheet using irr_dwl.csv, names clear
	gen part = "dwl"
	gen sig = pval < 0.10
	keep if rate == 0
	drop if part == "costs"
	gen type = "irr"
	keep sex `stat' part sig type
	destring `stat', replace
	tempfile irrdwl
	save `irrdwl', replace


	// discount
	insheet using bc_discount.csv, names clear
	gen part = "discount" + string(rate)
	gen sig = pval < 0.10
	gen rate_s = string(rate)
	keep if inlist(rate_s, "0", ".05")
	gen type = "bcr"
	keep sex `stat' part sig type
	destring `stat', replace
	tempfile discount
	save `discount', replace

	// npv
	insheet using ../tables/npv_type2.csv, names clear
	gen sig_tmp = value < 0.10 & type == "pval"
	bysort sex part: egen sig = max(sig_tmp)
	drop sig_tmp
	keep if type == "`stat'"
	drop type
	keep if inlist(part, "cc", "crime", "edu", "health", "inc_labor", "inc_parent", "qaly", "transfer")
	gen type = "npv"
	rename value `stat'
	tempfile npv
	save `npv', replace

	// combine
	use `bcrfactor', clear
	append using `irrfactor'
	append using `bcrdwl'
	append using `irrdwl'
	append using `discount'
	append using `npv'
	
	// rehape
	order part sex type `stat' sig
	reshape wide `stat' sig, i(part  type) j(sex) string
	reshape wide `stat'f sigf `stat'm sigm `stat'p sigp, i(part) j(type) string

	foreach v of varlist _all {
		capture confirm string var `v'
		if _rc {
			if strpos("`v'", "npv") & "`stat'" != "pval" {
				replace `v' = round(`v',1)
			}
			else {
				replace `v' = round(`v', 0.01)
			}
			rename `v' `v'old
			gen `v' = string(`v'old)
			order `v', after(`v'old)
			drop `v'old
			}
	}

	// deal with strings
	foreach v of varlist `stat'* {
		replace `v' = "" if `v' == "."
		replace `v' = "0" + `v' if strpos(`v', ".") == 1
		*replace `v' = "-0" + `v' if strpos(`v', "-") == 1 & strpos(`v', ".") == 2
		replace `v' = `v' + ".0" if strpos(`v', ".") == 0 & `v' != ""
		gen tmp = strpos(`v', ".")
		* positive
		replace `v' = substr(`v', 1,1) + "," + substr(`v',2,.) if inlist(tmp,5) & substr(`v',1,1)!="-"
		replace `v' = substr(`v', 1,2) + "," + substr(`v',3,.) if inlist(tmp,6) & substr(`v',1,1)!="-"
		replace `v' = substr(`v', 1,3) + "," + substr(`v',4,.) if inlist(tmp,7) & substr(`v',1,1)!="-"
		* negative
		replace `v' = substr(`v', 1,2) + "," + substr(`v',3,.) if inlist(tmp,6) & substr(`v',1,1)=="-"
		replace `v' = substr(`v', 1,3) + "," + substr(`v',4,.) if inlist(tmp,7) & substr(`v',1,1)=="-"
		replace `v' = substr(`v', 1,4) + "," + substr(`v',5,.) if inlist(tmp,8) & substr(`v',1,1)=="-"
		* deal with double decimal conistency
		drop tmp
		replace `v' = `v' + "0" if length(`v') - strpos(`v', ".") == 1
		if strpos("`v'", "npv") {
			replace `v' = subinstr(`v', ".00", "", .)
		}
	}
	
	if "`stat'" == "se" {
		foreach v of varlist `stat'* {
			replace `v' = "(" + `v' + ")"
		}
	}
	
	if "`stat'" == "pval" {
		foreach v of varlist `stat'* {
			replace `v' = "(" + `v' + ")"
		}
	}
	
	if "`stat'" == "point"{
		foreach v of varlist `stat'* {
			local suffix = subinstr("`v'", "`stat'", "", .)
			replace `v' = "\textbf{" + `v' + "}" if sig`suffix' == "1"
		}
	}
	
	// replace empty cells
	foreach v of varlist `stat'* {
		replace `v' = "" if `v' == "[]"
		replace `v' = "" if `v' == "()"
		replace `v' = subinstr(`v', "(0)", "(0.00)",.)
	}

	// organize data
	drop sig*
	gen order = .
	local i = 1
	foreach o in 0 6 8 11 10 9 7 5 3 1 2 4 {
		replace order = `o' in `i'
		local i = `i' + 1
	}

	sort order
	order part `stat'fnpv `stat'firr `stat'fbcr `stat'mnpv `stat'mirr `stat'mbcr `stat'pnpv `stat'pirr `stat'pbcr order

	// label
	replace part = "None" if part == "base"
	replace part = "Parental Income" if part == "inc_parent"
	replace part = "Subject QALY" if part == "qaly"
	replace part = "Subject Labor Income" if part == "inc_labor"
	replace part = "Subject Transfer Income" if part == "transfer"
	replace part = "Medical Expenditures" if part == "health"
	replace part = "Control Contamination" if part == "cc"
	replace part = "Education Costs" if part == "edu"
	replace part = "Crime Costs" if part == "crime"
	replace part = "Deadweight Loss" if part == "dwl"
	replace part = "0\% Discount Rate" if part == "discount0"
	replace part = "5\% Discount Rate" if part == "discount.05"


	// add column separators 
	local i = 1
	foreach v of varlist part - `stat'pirr {
		gen amp`i' = "&"
		order amp`i', after(`v')
		local i = `i' + 1 
	}	
	gen amp`i' = "\\"
	order amp`i', after(`stat'pbcr)
	
	if "`stat'" == "pval" replace amp10 = "\\\\" if inlist(order,0,8,9)
	
	// rename columns
	foreach v of varlist `stat'fnpv - `stat'pbcr {
		local newname = subinstr("`v'", "`stat'", "", .)
		rename `v' `newname'
	}
	
	// tag the type of table by the statistics it contains
	gen stat = "`stat'"
	
	// save the table
	tempfile table_`stat'
	save `table_`stat'', replace
}

use `table_point', clear
append using `table_se'
append using `table_pval'

replace stat = "1. point" if stat == "point"
replace stat = "2. se" if stat == "se"
replace stat = "3. pval" if stat == "pval"

replace part = "" if stat == "2. se"
replace part = "" if stat == "3. pval"

drop if stat == "3. pval"

sort order stat
drop order stat

// save
outsheet using "$output/sensitivity_stacked.txt", noquote nonames replace
