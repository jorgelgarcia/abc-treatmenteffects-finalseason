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

// output plots
cd $output

// ratios
foreach file in ratios irr {
	foreach type of numlist 2 5 8  {
		foreach sex in f m p {
			di "`file'`type', `sex'"
			
			preserve
			keep if male == "`sex'"
			// point estimate
			summ `file'`type' if b1 == 0 & b2 == 0
			local point   = round(r(mean),.001)
			
			// non-trim standard error
			summ `file'`type', d
			local pointse  = round(r(sd),.001)
			local pointme  = r(mean)
			local pointp1  = r(p1)
			local pointp5  = r(p5)
			local pointp10 = r(p10)
			local pointp90 = r(p90)
			local pointp95 = r(p95)
			local pointp99 = r(p99)
			local total    = r(N)
			summ `file'`type' if `file'`type' > 0
			local propz = round(100*(`total' - r(N))/`total',.01) 
			
			replace `file'`type' = `file'`type' - r(mean) + 1   if "`file'" == "ratios"
			replace `file'`type' = `file'`type' - r(mean) + .03 if "`file'" == "irr"
			gen     `file'`type'`sex'ind = 0
			replace `file'`type'`sex'ind = 1 if `file'`type' > `point'
			summ    `file'`type'`sex'ind
			local pointp = round(r(mean),.001)
			restore 
			
			// trim 1/99
			preserve
			keep if male == "`sex'"
			keep if `file'`type' > `pointp1' & `file'`type' < `pointp99'
			summ `file'`type' 
			local pointse2  = round(r(sd),.001)
			local pointme2  = r(mean)
			replace `file'`type' = `file'`type' - r(mean) + 1    if "`file'" == "ratios"
			replace `file'`type' = `file'`type' - r(mean) + .03  if "`file'" == "irr"
			gen `file'`type'`sex'ind = 0 
			replace `file'`type'`sex'ind = 1 if `file'`type' > `point'
			summ `file'`type'`sex'ind
			local pointp2 = round(r(mean),.001)
			restore
			
			// plot
			preserve
			keep if male == "`sex'"
			#delimit
			twoway (kdensity `file'`type', lwidth(medthick) lpattern(solid) lcolor(gs0))
				, 
					  legend(off)
					  xlabel(, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
					  xtitle(" ") ytitle(Density, size(small))
					  graphregion(color(white)) plotregion(fcolor(white))
					  note("Case 1: `point'(`pointse')[`pointp']; Case 2: `point'(`pointse2')[`pointp2'].     < 0, `propz'%");
			#delimit cr 
			graph export `file'_`type'_sex`sex'.eps, replace
			// di in r "Enter after seeing Figure" _request(Hello)
			restore
		}
	}
}

/*
// irr
foreach file in irr {
	foreach type of numlist 2 5 8{
		foreach sex in f m p {
			di "`file'`type', `sex'"
			
			preserve
			keep if male == "`sex'"
			// point estimate
			summ `file'`type' if b1 == 0 & b2 == 0
			local point   = round(r(mean),.0001)
			
			// non-trim standard error
			summ `file'`type', d
			local pointse  = round(r(sd),.0001)
			local pointme  = r(mean)
			local pointp1  = r(p1)
			local pointp5  = r(p5)
			local pointp10 = r(p10)
			local pointp90 = r(p90)
			local pointp95 = r(p95)
			local pointp99 = r(p99)
			
			replace `file'`type' = `file'`type' - r(mean) + .03
			gen     `file'`type'`sex'ind = 0
			replace `file'`type'`sex'ind = 1 if `file'`type' > `point'
			summ    `file'`type'`sex'ind
			local pointp = round(r(mean),.0001)
			restore 
			
			// trim 0/inf
			preserve
			keep if male == "`sex'"
			summ irr`type' 
			local tot = r(N)
			keep if irr`type' > 0
			summ `file'`type'
			local zp  = round((`tot' - r(N))/`tot',.001)
			local pointse2  = round(r(sd),.001)
			local pointme2  = r(mean)
			replace `file'`type' = `file'`type' - r(mean) + .03
			gen `file'`type'`sex'ind = 0 
			replace `file'`type'`sex'ind = 1 if `file'`type' > `point'
			summ `file'`type'`sex'ind
			local pointp2 = round(r(mean),.001)
			restore
			
			// plot
			preserve
			keep if male == "`sex'"
			#delimit
			twoway (kdensity `file'`type', lwidth(medthick) lpattern(solid) lcolor(gs0))
				, 
					  legend(off)
					  xlabel(, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
					  xtitle(" ") ytitle(Density, size(small))
					  graphregion(color(white)) plotregion(fcolor(white))
					  note("Case 1: `point'(`pointse')[`pointp']; Case 2: `point'(`pointse2')[`pointp2'].     Proportion < 0, `zp'");
			#delimit cr 
			graph export `file'_`type'_sex`sex'_new.eps, replace
			di in r "Enter after seeing Figure" _request(Hello)
			restore
		}
	}
}