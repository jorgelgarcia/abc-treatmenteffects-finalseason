version 12.0
set more off
clear all
set matsize 11000

/*
Project :       ABC CBA
Description:    this .do file makes exercises to sensitivity to non-compliance for critiques appendix, ABC sample only.
*This version:  April 18, 2016
*This .do file: Jorge L. Garcia
*This project : CBA Team
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

// abc sample
keep if abc == 1

/*
// first exercise, non-compliance of children 900, 912, 922... drop rest of the cases
preserve
drop if id == 99 | id == 95 | id == 124 | id == 906 | id == 82 | id == 119 /// 
                 | id == 85 | id == 103 | id == 108 | id == 123 

foreach var of varlist iq3y iq5y {
	reg `var' R
	est sto `var'_itt
	
	ivreg2 `var' (D = R)
	est sto `var'_iv
}


cd $output
# delimit
	outreg2 [iq3y_itt iq3y_iv iq5y_itt iq5y_iv]
			using abc_noncomp_e1, replace                                  
			tex dec(3) par(se) r2 nocons label noni nonotes
			keep(R D) ;
# delimit cr
restore 
*/

// add min to the treatment group guys who dissapeared CASES A to D
// preserve
drop if id == 99 | id == 95 | id == 124 | id == 906 | id == 82 | id == 119 /// 
                 | id == 85 | id == 103 | id == 108 | id == 123 
		 
local N4 = _N + 4 
set obs `N4'

// imput min IQ in treatment group
foreach var of varlist iq3y iq5y {
	summ `var' if treat == 1
	replace `var' = r(min) if id == . 
}

// randomized to treatment, no treatment take-up
replace R = 1 if id == . 
replace D = 0 if id == .

foreach var of varlist iq3y iq5y {
	reg `var' R
	est sto `var'_itt
	
	ivreg2 `var' (D = R)
	est sto `var'_iv
}


cd $output
# delimit
	outreg2 [iq3y_itt iq3y_iv iq5y_itt iq5y_iv]
			using abc_noncomp_e2, replace                                  
			tex dec(3) par(se) r2 nocons label noni nonotes
			keep(R D) ;
# delimit cr
 
