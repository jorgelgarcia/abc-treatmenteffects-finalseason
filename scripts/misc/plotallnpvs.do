version 12.0
set more off
clear all
set matsize 11000
set maxvar  32000

/*
Project :       ABC, CARE Treatment Effects / CBA
Description:    plot NPVs of type 2
*This version:  April 20, 2015
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
global scripts    = "$projects/abccare-cba/scripts/"
// ready data
global data       = "$klmmexico/abccare/irr_ratios/current/"
global specialed  = "$klmmexico/abccare/NPV/speccost/current/"

// output
global output     = "$projects/abccare-cba/output/"

cd $data
import excel using "npvs_collection.xlsx"

rename A sex
rename B npv

drop if npv < 0
drop if npv > 1.627e+15


global baseNPVp 	636674
global baseNPVm   	919049
global baseNPVf 	161759

foreach sex in p m f {
	summ npv if sex == "`sex'", det
	local a`sex' = r(mean)
	local a`sex' = string(`a`sex'', "%12.0fc")
	local m`sex' = r(p50)
	local m`sex' = string(`m`sex'', "%12.0fc")
}

replace npv = npv/1000

# delimit ;
twoway 		(kdensity npv if sex == "p",  	lcolor(gs10)  lpattern(dash) lwidth(vthick)    xline(${baseNPVp}, lwidth(vthick) lcolor(gs10) lpattern(dash)))
	       (kdensity npv if sex == "f",   	lcolor(gs0)  lpattern(solid) lwidth(vthick)    xline(${baseNPVf}, lwidth(vthick) lcolor(gs0) lpattern(solid)))
	       (kdensity npv if sex == "m",   lcolor(gs0) lpattern(".") lwidth(vthick)       xline(${baseNPVm}, lwidth(vthick) lcolor(gs0) lpattern("."))),
				legend(order(1 2 3) label(1 "Pooled") label(2 "Females") label(3 "Males") row(1))
				xtitle("Net Present Values (1,000s USD)") ytitle(Density)
				xlabel(#8, labsize(small)) ylabel(0.000000 "0" 0.001 "1/100" 0.002 "2/100" 0.003 "3/100", format(%9.6fc) labsize(small) angle(360))
				graphregion(color(white)) plotregion(fcolor(white))
				note("The vertical line represents the baseline estimate."
						"Average. Pooled: `ap'. Females: `af'. Males: `am'."
						"Median. Pooled: `mp'. Females: `mf'. Males: `mm'.");
#delimit cr
cd $output
graph export overalldist_npv.eps, replace
	
	
	/*
	twoway 		(kdensity npv if sex == "p",   width(200000) fcol(gs8) lwidth(thick) lcol(gs8)    	start(0)	xline(${baseNPVp}, lwidth(vthick) lcolor(gs8)))
			(kdensity npv if sex == "f",  	width(200000) fcol(gs12) lwidth(thick) lcolor(gs12)  	 start(0)	xline(${baseNPVf}, lwidth(vthick) lcolor(gs12)))
			(histogram npv if sex == "m",   width(200000) fcol(none) lcolor(black) lwidth(thick) start(0)	xline(${baseNPVm}, lwidth(vthick) lcolor(black))),
				legend(order(1 2 3) label(1 "Pooled") label(2 "Females") label(3 "Males") row(1))
				xtitle(" ") ytitle(Density)
				xlabel(#8, labsize(small)) ylabel(#4)
				graphregion(color(white)) plotregion(fcolor(white))
				note("The vertical line represents the baseline estimate."
						"Average. Pooled: `ap'. Females: `af'. Males: `am'."
						"Median. Pooled: `mp'. Females: `mf'. Males: `mm'.");
