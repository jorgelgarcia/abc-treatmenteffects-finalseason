version 12.0
set more off
clear all
set matsize 11000
set maxvar  32000

/*
Project :       ABC, CARE Treatment Effects / CBA
Description:    sensitvity to different control sets
*This version:  July 7, 2015
*This .do file: Jorge L. Garcia
*/

// set environment variables (server)
global erc: env erc
global projects: env projects
global klmshare:  env klmshare
global klmmexico: env klmMexico
global googledrive: env googledrive

// set general locations
// do files
global scripts    = "$projects/abc-treatmenteffects-finalseason/scripts/"
// ready data
global data       = "$klmmexico/abccare/sensitivity_TE/sep-5-2016b"
// output
global output     = "$projects/abc-treatmenteffects-finalseason/output/"

foreach sex in female male {
	foreach outcome in si30y_works years_30y {
		cd $data
		use for_sensitivity_TE_`sex'_`outcome'.dta, clear
		foreach var of varlist itt_wctrl epan_ipw_P0 epan_ipw_P1 {
			summ    `var' if controln == 215
			local mcont  = r(mean)
			
			summ `var', d
			drop if `var' < r(p1) | `var' > r(p99)
			
			#delimit
			twoway (kdensity `var' if control >= 1   & control <= 12, lwidth(medthick) lpattern(solid) lcolor(gs0) xline(`mcont', lwidth(medthick) lpattern("....._") lcolor(gs0)))
			       (kdensity `var' if control >= 13 & control  <= 78, lwidth(medthick) lpattern(dash)  lcolor(gs0))
			       (kdensity `var' if control >= 79 & control  <= 298, lwidth(medthick) lpattern(solid) lcolor(gs10))	
			       (function y = `mcont', horizontal lwidth(medthick) lpattern("....._") lcolor(gs0))
				, 
					  legend(label(1 One Control) label(2 Two Controls) label(3 Three Controls) 
					         label(4 Baseline Point Estimate) cols(3) rows(2))
					  xlabel(, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
					  xtitle(Point Estimate) ytitle(Density)
					  graphregion(color(white)) plotregion(fcolor(white));
			#delimit cr
			cd $output
			graph export sencontrols_`sex'_`outcome'_`var'.eps, replace
			di in r "Enter after seeing Figure" _request(Hello)
		}
	}
}
