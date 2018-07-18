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
global data       = "$klmmexico/abccare/irr_ratios/current/"
// output
global output       = "$projects/abccare-cba/output/"

// abc
// open data
cd $data
set obs 16875
gen b = _n

// pooled estimates
foreach file in irr ratios {
	foreach type of numlist 2 5 8 {
		preserve
		cd $data
		cd "type`type'"
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
foreach type of numlist 2 5 8  {
	foreach sex in f m p {
		di "type `type', sex `sex'"
		
		preserve
		keep if male == "`sex'"
		// point estimate
		// drop if b1 == 0 & b2 == 0
		summ ratios`type', detail
		local p5  = r(p5)
		local p95 = r(p95) 
		drop if ratios`type' < r(p5) | ratios`type' > r(p95)
	
		summ  ratios`type'
		local point    = round(r(mean),.01)
		local pointnr  = r(mean)
		local pointse  = round(r(sd),.01)
		
		replace ratios`type' = ratios`type' - `pointnr' + 1
		gen     ratios`type'`sex'ind = 0
		replace ratios`type'`sex'ind = 1 if ratios`type' > `pointnr'
		summ    ratios`type'`sex'ind
		local pointp = round(r(mean),.01)
		restore 
		
		// plot
		preserve
		keep if male == "`sex'"
		keep if ratios`type' > `p5' & ratios`type' < `p95'
		#delimit
		twoway (kdensity ratios`type', lwidth(vthick) lpattern(solid) lcolor(gs0))
			, 
				  legend(off)
				  xlabel(, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
				  xtitle(" ") ytitle(Density, size(small))
				  graphregion(color(white)) plotregion(fcolor(white))
				  note("Point Estimate: `point'(`pointse')[`pointp'].");
		#delimit cr 
		graph export ratios_`type'_sex`sex'.eps, replace
		// di in r "Enter after seeing Figure" _request(Hello)
		restore
	}
}

// irr
foreach type of numlist 2 {
	foreach sex in f m p {
		di "type `type', sex `sex'"
		
		preserve
		keep if male == "`sex'"
		summ irr`type'd abc-	
		local Nt = r(N)
		drop if irr`type' <= 0 | irr`type' == .
		summ irr`type'
		local Nc = r(N)
		
		local perc = `Nc'/`Nt'
		local perc = `perc'
		local perc = round(`perc',.00001)
		
		summ  irr`type'
		local point    = round(r(mean),.00001)
		local pointnr  = r(mean)
		local pointse  = round(r(sd),.00001)
		
		replace irr`type' = irr`type' - `pointnr' + .03
		gen     irr`type'`sex'ind = 0
		replace irr`type'`sex'ind = 1 if irr`type' > `pointnr'
		summ    irr`type'`sex'ind
		local pointp = round(r(mean),.01)
		restore 
		
		// plot
		preserve
		keep if male == "`sex'"
		drop if irr`type' <= 0 | irr`type' == .
		#delimit
		twoway (kdensity irr`type', lwidth(vthick) lpattern(solid) lcolor(gs0))
			, 
				  legend(off)
				  xlabel(, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
				  xtitle(" ") ytitle(Density, size(small))
				  graphregion(color(white)) plotregion(fcolor(white))
				  note("Point Estimate: `point'(`pointse')[`pointp']. Proportion > 0: `perc'");
		#delimit cr 
		graph export irr_`type'_sex`sex'.eps, replace
		// di in r "Enter after seeing Figure" _request(Hello)
		restore
	}
}
