version 12.0
set more off
clear all
set matsize 11000
set maxvar  32000

/*
Project :       CARE AND ABC
Description:    this .do file plots the ABC and CARE HRIs
*This version:  January 21, 2015
*This .do file: Jorge L. Garcia
*This project : HRI 
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
global datapsid    = "$klmshare/Data_Central/data-repos/psid/base/"
global dataabccare = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
// output
global output     = "$projects/abc-treatmenteffects-finalseason/output/"

// open merged data
cd $dataabccare
use append-abccare_iv.dta, clear

cd $output

// CARE
// plot
# delimit
twoway (histogram hrabc_index if abc == 0, start(10) discrete fraction color(gs0)  barwidth(.75)),
	   xtitle(High Risk Index) ytitle(Fraction)
	   xlabel(, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
	   graphregion(color(white)) plotregion(fcolor(white));
#delimit cr
graph export care_hri.eps, replace


// ABC
// plot
cd $output
# delimit
twoway (histogram hrabc_index if care == 0, start(10) discrete fraction color(gs0)  barwidth(.75)),
	   xtitle(High Risk Index) ytitle(Fraction)
	   xlabel(, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
	   graphregion(color(white)) plotregion(fcolor(white));
#delimit cr
graph export abc_hri.eps, replace
