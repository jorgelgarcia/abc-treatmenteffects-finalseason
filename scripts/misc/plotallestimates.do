version 12.0
set more off
clear all
set matsize 11000
set maxvar  32000

/*
Project :       ABC, CARE Treatment Effects / CBA
Description:    plot estimates throughout the paper
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
global scripts    = "$projects/abc-treatmenteffects-finalseason/scripts/"
// ready data
global data       = "$klmmexico/abccare/irr_ratios/current/"
global specialed  = "$klmmexico/abccare/NPV/speccost/current/"

// output
global output     = "$projects/abc-treatmenteffects-finalseason/output/"

cd $output

import excel cost-benefit-analysis.xlsx, firstrow

replace  IRR = " " if IRR == "-"
destring IRR, replace

global baseBCRatioPooled 7.33
global baseBCRatioMale   10.19
global baseBCRatioFemale 2.61

global baseIRRPooled 13.7
global baseIRRMale   14.7
global baseIRRFemale 10.1

replace IRR = IRR*100 

foreach stat in BCRatio IRR {
	
	foreach sample in Pooled Male Female {
		summ if Sample == "`sample'", det
		local a`Sample' = r(mean)
		local a`Sample' = string(a`Sample', "%3.2f")
		local m`Sample' = r(p50)
		local m`Sample' = string(m`Sample', "%3.2f")
	}

	# delimit
	twoway (kdensity `stat' if Sample == "Pooled" & BCRatio <= 16,   lcolor(gs10)  lpattern(dash) lwidth(vthick)    xline(${base`stat'Pooled}, lwidth(vthick) lcolor(gs10) lpattern(dash)))
	       (kdensity `stat' if Sample == "Female" & BCRatio <= 16,   lcolor(gs0)  lpattern(solid) lwidth(vthick)    xline(${base`stat'Female}, lwidth(vthick) lcolor(gs0) lpattern(solid)))
	       (kdensity `stat' if Sample == "Male"   & BCRatio <= 16,   lcolor(gs0) lpattern(".") lwidth(vthick)       xline(${base`stat'Male}, lwidth(vthick) lcolor(gs0) lpattern("."))),
		   legend(order(1 2 3) label(1 "Pooled") label(2 "Females") label(3 "Males") row(1))
		   xtitle(" ") ytitle(Density)
		   graphregion(color(white)) plotregion(fcolor(white))
		   note("The vertical line represents the baseline estimate."
		        "Average. Pooled: `aPooled'. Females: `aFemale'. Males: `aMale'."
			"Median. Pooled: `mPooled'. Females: `mFemale'. Males: `mMale'.");
	#delimit cr
	graph export overalldist_`stat'.eps, replace
	
}
