version 12.0
set more off
clear all
set matsize 11000

/*
Project :       ABC
Description:    plot estimates conditional on IQ
*This version:  April 18, 2016
*This .do file: Jorge L. Garcia
*This project : All except Seong, B. and CC. 
*/

// set environment variables (server)
global erc: env erc
global projects: env projects
global klmshare:  env klmshare
global klmmexico: env klmMexico
global googledrive: env googledrive

// set general locations
// do files
global scripts     = "$projects/abc-treatmenteffects-finalseason/scripts/"
// ready data
global dataresults = "$klmmexico/abccare/outputfiles/may-26"
// output
global output      = "$projects/abc-treatmenteffects-finalseason/output/"

cd $dataresults/abccare/csv

local sexind = 2
foreach sex in male female {
	local sexind = `sexind' - 1
	insheet using rslt_`sex'_counts_n10a10.csv, clear
	foreach s in point pval se {
		preserve
		drop index
		keep if stat == "`s'"
		foreach var of varlist * {
			rename `var' `var'_`s'
		}
		rename category_`s' category
		tempfile abccare_`s'
		drop stat
		save "`abccare_`s''", replace
		restore
	}
		
	use "`abccare_point'", clear
	foreach s in pval se {		
	merge 1:1 category using "`abccare_`s''"
		tab _merge
		keep if _merge == 3
		drop _merge
	}
	
	gen male = `sexind'
	tempfile abccare_`sex'_all
	save "`abccare_`sex'_all'", replace
}
append using "`abccare_male_all'"
tempfile `program'_all
save "``program'_all'", replace

// keep HOME socres
keep if category == "HOME Scores" | category == "Parent Income"

// creat category index
gen catindex = .
replace catindex = 0  if category == "Parent Income" 
replace catindex = 1  if category == "HOME Scores"

sort catindex male
drop if catindex == .

// plots
gen catfemale =  catindex*3 - 1
gen catmale   =  catfemale + 1
global xlabels1 -.5 "Parents' Income" 2.5 "HOME Scores"


cd $output
foreach var in itt_noctrl {
	gen `var'_min = `var'_point - `var'_se
	gen `var'_max = `var'_point + `var'_se

	// plot all positive treatment effects
	# delimit
	twoway (bar `var'_point catfemale if male == 0, color(gs8))
	       (bar `var'_point catmale   if male == 1, color(gs4))
	       (rcap `var'_max `var'_min catfemale if male == 0, lcolor(gs0))
	       (rcap `var'_max `var'_min catmale   if male == 1, lcolor(gs0))
	       (function y = 50, range(1.5 3.5) lwidth(thick) lcolor(gs0)),
	       legend(row(1) cols(3) order(1 "Females" 2 "Males" 4 "+/- s.e."))
			  xlabel($xlabels1, noticks grid glcolor(white)) 
			  ylabel(0[20]100, angle(h) glcolor(gs14))
			  xtitle("", size(small)) 
			  ytitle("% of Outcomes with Positive TE", size(small))
			  graphregion(color(white)) plotregion(fcolor(white));
	# delimit cr
	graph export `var'_cats1_sig10.eps, replace
}
