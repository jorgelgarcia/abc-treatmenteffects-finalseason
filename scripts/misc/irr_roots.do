version 12.0
set more off
clear all
set matsize 11000
set maxvar  32000

/*
Project :       ABC, CARE Treatment Effects / CBA
Description:    this .do file investigates the IRR/BC distributions
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
global data       = "$klmmexico/abccare/irr_ratios/jul-07"
// output
global output     = "$projects/abc-treatmenteffects-finalseason/output/"

// abc
// open data
cd $data
set obs 16875
gen b = _n

// pooled estimates
foreach type of numlist 2 5 8 {
	preserve
	insheet using all_roots_type`type'.csv, clear
	sort draw adraw
	gen b  = _n
	keep b sex adraw draw v*
	egen totroot`type' = rownonmiss(v*)
	foreach var of varlist v* {
		gen abs`var'  =  abs(`var')
		gen sign`var' =  1 if `var' > 0
		replace sign`var' = -1 if `var' < 0
	}
	egen absmin = rowmin(abs*)
	
	foreach var of varlist v* {
		replace absmin = sign`var'*absmin if absmin == abs`var'
	}
		
	rename absmin reproot`type'
	drop abs* v*
	tempfile roots`type'
	save "`roots`type''", replace
	restore
	merge 1:1 b using "`roots`type''"
	tab _merge
	drop _merge 
}


foreach type of numlist 2 5 8  {
	foreach sex in f m p {
		di "type `type', sex `sex'"
		preserve
		keep if sex == "`sex'"
		// point estimate
		summ reproot`type' if draw == 0 & adraw == 0
		local point  = r(mean)
		local pointr = round(r(mean),.001)
		
		// non-trim standard error
		summ  reproot`type', d
		local pointse  = round(r(sd),.001)
		local pointme  = r(mean)
		local pointp1  = r(p1)
		local pointp5  = r(p5)
		local pointp10 = r(p10)
		local pointp90 = r(p90)
		local pointp95 = r(p95)
		local pointp99 = r(p99)
		
		// percentage negative
		local total    = r(N)
		summ reproot`type' if reproot`type' > 0
		local propz = round(100*(`total' - r(N))/`total',.01)
		
		// percentage of negative with multiple roots
		summ reproot`type' if reproot`type' < 0
		gen mulroot`type' = 0 if totroot`type' == 1
		replace mulroot`type' = 1 if totroot`type' != 1 & totroot`type' != .
		summ mulroot`type' if reproot`type' < 0
		local mnegroots = round(100*r(mean),.01)
		
		// percentage multiple roots
		replace reproot`type' = reproot`type' - r(mean) + .03
		gen     reproot`type'`sex'ind = 0
		replace reproot`type'`sex'ind = 1 if reproot`type' > `point'
		summ    reproot`type'`sex'ind
		local pointp = round(r(mean),.001)
		restore 
		
		// trim 1/99
		preserve
		keep if sex == "`sex'"
		keep if reproot`type' > `pointp1' & reproot`type' < `pointp99'
		summ  reproot`type' 
		local pointse2  = round(r(sd),.001)
		local pointme2  = r(mean)
		replace reproot`type' = reproot`type' - r(mean) + .03
		gen reproot`type'`sex'ind = 0 
		replace reproot`type'`sex'ind = 1 if reproot`type' > `point'
		summ reproot`type'`sex'ind
		local pointp2 = round(r(mean),.001)
		restore
		
		// plot
		preserve
		keep if sex == "`sex'"
		#delimit
		twoway (kdensity reproot`type', lwidth(medthick) lpattern(solid) lcolor(gs0))
			, 
				  legend(off)
				  xlabel(, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
				  xtitle(" ") ytitle(Density, size(small))
				  graphregion(color(white)) plotregion(fcolor(white))
				  note("Case 1: `pointr'(`pointse')[`pointp']; Case 2: `pointr'(`pointse2')[`pointp2'].     < 0: `propz'%.     Multiple, < 0: `mnegroots'%");
		#delimit cr 
		graph export reproot`type'_`sex'.eps, replace
		di in r "Enter after seeing Figure" _request(Hello)
		restore
	}
}
