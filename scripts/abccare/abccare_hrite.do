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
global scripts        = "$projects/abc-treatmenteffects-finalseason/scripts/"
// ready data
global datapsidmatch   = "$klmshare/Data_Central/data-repos/psid/extensions/abc-match/"
global datanlsymatch   = "$klmshare/Data_Central/data-repos/nlsy/extensions/abc-match-nlsy/"
global dataCnlsymatch  = "$klmshare/Data_Central/data-repos/nlsy/extensions/abc-match-cnlsy/"
global dataabccare    = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
// output
global output      = "$projects/abc-treatmenteffects-finalseason/output/"

// ABC
cd $dataabccare
use append-abccare_iv.dta, clear
drop if random == 3

gen inter = R*hrabc_index

foreach var of varlist iq5y years_30y si30y_works_job {
	reg `var' R if  male == 1
	est sto `var'1
	reg `var' R inter if male == 1
	est sto `var'i1
	reg `var' R if  male == 0
	est sto `var'0
	reg `var' R inter if male == 0
	est sto `var'i0
}

cd $output
outreg2 [iq5y1 iq5yi1 years_30y1 years_30yi1 si30y_works_job1 si30y_works_jobi1 iq5y1 iq5yi0 years_30y0 years_30yi0 si30y_works_job0 si30y_works_jobi0] using abccare_hrites, replace tex(frag) alpha(.01, .05, .10) sym (***, **, *) dec(3) par(se) r2 nonotes
