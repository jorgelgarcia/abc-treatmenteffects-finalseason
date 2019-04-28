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
global dataresults = "$klmmexico/abccare/outputfiles/jun-24"
// output
global output      = "$projects/abc-treatmenteffects-finalseason/output/"


local progcount = 0
foreach program in abccare {
	cd $dataresults/`program'/csv
	local progcount = `progcount' + 1
	local sexind = 2
	foreach sex in male female {
		local sexind = `sexind' - 1
		insheet using rslt_`sex'_counts.csv, clear
		foreach s in point pval se {
			preserve
			drop index
			keep if stat == "`s'"
			foreach var of varlist * {
				rename `var' `var'_`s'
			}
			rename category_`s' category
			tempfile `program'_`s'
			drop stat
			save "``program'_`s''", replace
			restore
		}
		
		use "``program'_point'", clear
		foreach s in pval se {
			
			merge 1:1 category using "``program'_`s''"
			tab _merge
			keep if _merge == 3
			drop _merge
		}
		
		gen abc    = `progcount'
		gen male = `sexind'
		tempfile `program'_`sex'_all
		save "``program'_`sex'_all'", replace
	}
	append using "``program'_male_all'"
	tempfile `program'_all
	save "``program'_all'", replace
}

// append using "`abc_all'"
// append using "`care_all'"
tempfile all
save "`all'", replace

// plots
gen abcfemale = abc*3 - 1
gen abcmale   = abc*3

// plot positive treatment effect counts
sort category
gen index = _n

global itt_noctrl_label  % of Outcomes with Positive TE
global epan_ipw_p0_label % of Outcomes with Positive TE (adjusted) 
global epan_ipw_p1_label % of Outcomes with Positive TE (adjusted)

cd $output 
foreach var in itt_noctrl epan_ipw_p0 epan_ipw_p1 {
	gen `var'_min = `var'_point - `var'_se
	gen `var'_max = `var'_point + `var'_se

	// plot all positive treatment effects
	# delimit
	twoway (bar `var'_point abcfemale if male == 0 & index > 2, color(gs6))
	       (bar `var'_point abcmale   if male == 1 & index > 2, color(black))
	       (rcap `var'_max `var'_min abcfemale if male == 0 & index > 2, lcolor(gs0))
	       (rcap `var'_max `var'_min abcmale   if male == 1 & index > 2, lcolor(gs0)),
	       legend(row(1) cols(3) order(1 "Females" 2 "Males" 4 "+/- s.e."))
			  xlabel("",noticks grid glcolor(white)) 
			  ylabel(0[20]80, angle(h) glcolor(gs14))
			  xtitle("", size(small)) 
			  ytitle("${`var'_label}", size(small))
			  graphregion(color(white)) plotregion(fcolor(white));
	# delimit cr
	graph export `var'_all.eps, replace
	
	// plot all positive and significant treatment effects
	# delimit
	twoway (bar `var'_point abcfemale if male == 0 & index <= 2, color(gs6))
	       (bar `var'_point abcmale   if male == 1 & index <= 2, color(black))
	       (rcap `var'_max `var'_min abcfemale if male == 0 & index <= 2, lcolor(gs0))
	       (rcap `var'_max `var'_min abcmale   if male == 1 & index <= 2, lcolor(gs0)),
	       legend(row(1) cols(3) order(1 "Females" 2 "Males" 4 "+/- s.e."))
			  xlabel("",noticks grid glcolor(white)) 
			  ylabel(0[20]80, angle(h) glcolor(gs14))
			  xtitle("", size(small)) 
			  ytitle("${`var'_label}, significant at 10%", size(small))
			  graphregion(color(white)) plotregion(fcolor(white));
	# delimit cr
	graph export `var'_all_sig10.eps, replace
}
