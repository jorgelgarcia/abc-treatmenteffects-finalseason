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
global dataresults = "$klmmexico/abccare/outputfiles/jun-16"
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


// creat category index
gen catindex = .
replace catindex = 0  if category == "Parent Income" 
replace catindex = 1  if category == "HOME Scores"
replace catindex = 3  if category == "Achievement Scores" 
replace catindex = 2  if category == "IQ Scores" 
replace catindex = 4  if category == "Mental Health"
replace catindex = 5  if category == "Education" 
replace catindex = 6  if category == "Employment and Income"
replace catindex = 7  if category == "Crime"
replace catindex = 8  if category == "Mean Health"
replace catindex = 9  if category == "Cholesterol"
replace catindex = 10 if category == "Diabetes"
replace catindex = 11 if category == "Hypertension"
replace catindex = 12 if category == "Self-Reported Health"
replace catindex = 13 if category == "Tobacco, Drugs, Alcohol"
replace catindex = 14 if category == "Obesity"

sort catindex male
drop if catindex == .

// plots
gen catfemale = catindex*3 - 1
gen catmale   =  catfemale + 1

# delimit
global xlabels1 -.5 "Parents' Income" 2.5 "HOME Scores" 5.5 "IQ Scores"
		  8.5 "Achievement Scores" 11.5 "Mental Health"
		  14.5 "Education" 17.5 "Employment and Income" 
		  20.5 "Crime";

global xlabels2  26.5 "Cholesterol" 29.5 "Diaebtes" 32.5 "Hypertension" 
		 35.5 "Self-Reported Health" 38.5 "Tobacco, Drugs, Alcohol"
		 41.5 "Obesity"; 
# delimit cr

cd $output
foreach var in itt_noctrl epan_ipw_p0 epan_ipw_p1 {
	gen `var'_min = `var'_point - `var'_se
	gen `var'_max = `var'_point + `var'_se

	// plot all positive treatment effects
	# delimit
	twoway (bar `var'_point catfemale if male == 0 & catfemale <= 20, color(gs6))
	       (bar `var'_point catmale   if male == 1 & catmale   <= 21, color(black))
	       (rcap `var'_max `var'_min catfemale if male == 0 & catfemale <= 20, lcolor(gs0))
	       (rcap `var'_max `var'_min catmale   if male == 1 & catmale   <= 21, lcolor(gs0)),
	       legend(row(1) cols(3) order(1 "Females" 2 "Males" 4 "+/- s.e."))
			  xlabel($xlabels1, angle(45) noticks grid glcolor(white)) 
			  ylabel(0[20]100, angle(h) glcolor(gs14))
			  xtitle("", size(small)) 
			  ytitle("% of Outcomes with Positive TE (adjusted), significant at 10\%", size(vsmall))
			  graphregion(color(white)) plotregion(fcolor(white));
	# delimit cr
	graph export `var'_cats1_sig10.eps, replace
	
	
	// plot all positive treatment effects
	# delimit
	twoway (bar `var'_point catfemale if male == 0 & catfemale > 20, color(gs6))
	       (bar `var'_point catmale   if male == 1 & catmale   > 21, color(black))
	       (rcap `var'_max `var'_min catfemale if male == 0 & catfemale > 20, lcolor(gs0))
	       (rcap `var'_max `var'_min catmale   if male == 1 & catmale   > 21, lcolor(gs0)),
	       legend(row(1) cols(3) order(1 "Females" 2 "Males" 4 "+/- s.e."))
			  xlabel($xlabels2, angle(45) noticks grid glcolor(white)) 
			  ylabel(0[20]100, angle(h) glcolor(gs14))
			  xtitle("", size(small)) 
			  ytitle("% of Outcomes with Positive TE (adjusted), significant at 10\%", size(vsmall))
			  graphregion(color(white)) plotregion(fcolor(white));
	# delimit cr
	graph export `var'_cats2_sig10.eps, replace
}
