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

global baseIRRPooled .137
global baseIRRMale   .147
global baseIRRFemale .101

foreach stat in BCRatio IRR {

	# delimit
	twoway (kdensity `stat' if Sample == "Pooled" & BCRatio <= 16,  lcolor(gs10)  lpattern(dash) lwidth(medthick)    xline(${base`stat'Pooled}, lcolor(gs10) lpattern(dash)))
	       (kdensity `stat' if Sample == "Female" & BCRatio <= 16, lcolor(gs0)  lpattern(solid) lwidth(medthick)    xline(${base`stat'Female}, lcolor(gs0) lpattern(solid)))
	       (kdensity `stat' if Sample == "Male"   & BCRatio <= 16,   lcolor(gs0) lpattern(".") lwidth(medthick) xline(${base`stat'Male}, lcolor(gs0) lpattern("."))),
		   legend(order(1 2 3) label(1 "Females and Males") label(2 "Females") label(3 "Males") row(3))
		   xtitle(" ") ytitle(Density)
		   graphregion(color(white)) plotregion(fcolor(white))
		   note("The vertical line plots the baseline estimate.");
	#delimit cr
	graph export overalldist_`stat'.eps, replace
	
}
