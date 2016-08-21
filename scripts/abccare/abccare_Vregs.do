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
global output     = "$projects/abc-treatmenteffects-finalseason/output/"

// open merged data
cd $dataabccare
use append-abccare_iv.dta, clear
cd $output

// abc sample
drop if random == 3

foreach sex of numlist 0 1 {
	foreach var of varlist years_30y si30y_works_job {
		reg `var' P hrabc_index hh_sibs0y apgar1 apgar5 prem_birth   if R == 0 & male == `sex'
		est sto `var'`sex'P
		reg `var' Q hrabc_index hh_sibs0y apgar1 apgar5 prem_birth   if R == 0 & male == `sex'
		est sto `var'`sex'Q
		reg `var' P Q hrabc_index hh_sibs0y apgar1 apgar5 prem_birth if R == 0 & male == `sex'
		est sto `var'`sex'PQ
		
	}
}

foreach num of numlist 0 1{
	#delimit
	outreg2 [years_30y`num'P years_30y`num'Q years_30y`num'PQ si30y_works_job`num'P si30y_works_job`num'Q si30y_works_job`num'PQ] using abccare_Vregs`num', replace tex(frag) 
			alpha(.01, .05, .10) sym (***, **, *) dec(3) par(se) r2 keep(P Q) nocons;
	#delimit cr
}





