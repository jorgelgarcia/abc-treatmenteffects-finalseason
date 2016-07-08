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
foreach file in irr ratios {
	foreach type of numlist 2 5 8 {
		preserve
		insheet using all_`file'_type`type'.csv, clear
		gen b  = _n
		keep b v1 v2 v3 v4
		rename v1 male
		rename v2 b1
		rename v3 b2
		rename v4 `file'`type'
		tempfile `file'`type'
		save "``file'`type''", replace
		restore
		merge 1:1 b using "``file'`type''"
		tab _merge
		drop _merge 
	}
}
tempfile allestimates
save "`allestimates'", replace

// output plots
cd $output

// ratios
/*
foreach type of numlist 2 5 8  {
	foreach sex in f m p {
		di "type `type', sex `sex'"
		
		preserve
		keep if male == "`sex'"
		// point estimate
		summ ratios`type' if b1 == 0 & b2 == 0
		local point   = round(r(mean),.001)
		
		// non-trim standard error
		summ ratios`type', d
		local pointse  = round(r(sd),.001)
		local pointme  = r(mean)
		local pointp1  = r(p1)
		local pointp5  = r(p5)
		local pointp10 = r(p10)
		local pointp90 = r(p90)
		local pointp95 = r(p95)
		local pointp99 = r(p99)
		local total    = r(N)
		summ ratios`type' if ratios`type' > 0
		local propz = round(100*(`total' - r(N))/`total',.01) 
		
		replace ratios`type' = ratios`type' - r(mean) + 1
		gen     ratios`type'`sex'ind = 0
		replace ratios`type'`sex'ind = 1 if ratios`type' > `point'
		summ    ratios`type'`sex'ind
		local pointp = round(r(mean),.001)
		restore 
		
		// trim 1/99
		preserve
		keep if male == "`sex'"
		keep if ratios`type' > `pointp1' & ratios`type' < `pointp99'
		summ ratios`type' 
		local pointse2  = round(r(sd),.001)
		local pointme2  = r(mean)
		replace ratios`type' = ratios`type' - r(mean) + 1
		gen ratios`type'`sex'ind = 0 
		replace ratios`type'`sex'ind = 1 if ratios`type' > `point'
		summ ratios`type'`sex'ind
		local pointp2 = round(r(mean),.001)
		restore
		
		// plot
		preserve
		keep if male == "`sex'"
		#delimit
		twoway (kdensity ratios`type', lwidth(medthick) lpattern(solid) lcolor(gs0))
			, 
				  legend(off)
				  xlabel(, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
				  xtitle(" ") ytitle(Density, size(small))
				  graphregion(color(white)) plotregion(fcolor(white))
				  note("Case 1: `point'(`pointse')[`pointp']; Case 2: `point'(`pointse2')[`pointp2'].     < 0, `propz'%");
		#delimit cr 
		graph export ratios_`type'_sex`sex'.eps, replace
		// di in r "Enter after seeing Figure" _request(Hello)
		restore
	}
}*/

// irr
// first count roots
clear
cd $data
set obs 16875
gen b = _n

foreach type of numlist 2 5 8 {
	preserve
	insheet using all_roots_type`type'.csv, clear
	sort adraw draw
	gen b  = _n
	keep b sex adraw draw v*
	egen totroot`type' = rownonmiss(v*)
	rename v4 reproot`type'
	drop v*
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
		
		// percentage of negative with multiple roots
		summ reproot`type' if reproot`type' < 0
		gen mulroot`type' = 0 if totroot`type' == 1
		replace mulroot`type' = 1 if totroot`type' != 1 & totroot`type' != .
		summ mulroot`type' if reproot`type' < 0
		local mnegroots`type'`sex' = round(100*r(mean),.01)
		restore
	}
}

use "`allestimates'", clear
cd $output
foreach type of numlist 2 5 8  {
	foreach sex in f m p {
		di "type `type', sex `sex'"
		
		preserve
		keep if male == "`sex'"
		// point estimate
		summ irr`type' if b1 == 0 & b2 == 0
		local point   = round(r(mean),.001)
		
		// non-trim standard error
		summ irr`type', d
		local pointse  = round(r(sd),.001)
		local pointme  = r(mean)
		local pointp1  = r(p1)
		local pointp5  = r(p5)
		local pointp10 = r(p10)
		local pointp90 = r(p90)
		local pointp95 = r(p95)
		local pointp99 = r(p99)
		local total    = r(N)
		summ irr`type' if irr`type' > 0
		local propz = round(100*(`total' - r(N))/`total',.01) 
		
		replace irr`type' = irr`type' - r(mean) + .03
		gen     irr`type'`sex'ind = 0
		replace irr`type'`sex'ind = 1 if irr`type' > `point'
		summ    irr`type'`sex'ind
		local pointp = round(r(mean),.001)
		restore 
		
		// trim 1/99
		preserve
		sort b1 b2
		merge 1:1 b using "`roots`type''"
		keep if male == "`sex'"
		gen mulroot`type' = 0 if totroot`type' == 1
		replace mulroot`type' = 1 if totroot`type' != 1 & totroot`type' != .
		keep if mulroot`type' == 0 //  `pointp1' & irr`type' < `pointp99'
		summ irr`type' 
		local pointse2  = round(r(sd),.001)
		local pointme2  = r(mean)
		replace irr`type' = irr`type' - r(mean) + .03
		gen irr`type'`sex'ind = 0 
		replace irr`type'`sex'ind = 1 if irr`type' > `point'
		summ irr`type'`sex'ind
		local pointp2 = round(r(mean),.001)
		restore
		
		// plot
		preserve
		keep if male == "`sex'"
		#delimit
		twoway (kdensity irr`type', lwidth(medthick) lpattern(solid) lcolor(gs0))
			, 
				  legend(off)
				  xlabel(, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
				  xtitle(" ") ytitle(Density, size(small))
				  graphregion(color(white)) plotregion(fcolor(white))
				  note("Case 1: `point'(`pointse')[`pointp']; Case 2: `point'(`pointse2')[`pointp2'].     < 0: `propz'%.     < 0, Multiple: `mnegroots`type'`sex''%");
		#delimit cr 
		graph export irr_`type'_sex`sex'.eps, replace
		// di in r "Enter after seeing Figure" _request(Hello)
		restore
	}
}

