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
global datapsid    = "$klmshare/Data_Central/data-repos/psid/base/"
global dataabccare = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
// output
global output      = "$projects/abc-treatmenteffects-finalseason/output/"

// open merged data
cd $dataabccare
use append-abccare_iv.dta, clear
cd $output

// abc sample
drop if random == 3
drop if R != 0
keep if P == 1

replace Q = Q/61

#delimit
twoway (kdensity Q if male == 1, lwidth(medthick) lpattern(solid) lcolor(gs0) bwidth(.08))
        , 
		  legend(label(1 Males) label(2 Females) size(small))
		  xlabel(, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
		  xtitle(Months in Alternative Preschool from Ages 0 to 5) ytitle(Density, size(small))
		  graphregion(color(white)) plotregion(fcolor(white));
#delimit cr 
graph export abccare_monthsalt_V.eps, replace








