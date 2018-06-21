/*

Project:		ABC CBA
Script:			Table describing inputs for labor projections
Author:			Anna Ziff (aziff@uchicago.edu)
Original date:	February 1, 2018

*/

// options
cap file close
clear all

// filepaths
global klmshare : env klmshare
global projects : env projects

global data	   	= "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv"
global scripts    	= "$projects/abc-treatmenteffects-finalseason/scripts/"
global output      	= "$projects/abc-treatmenteffects-finalseason/output/"
global datacnlsyw       = "$klmshare/Data_Central/data-repos/nlsy/extensions/abc-match-cnlsy/"

// data
cd $data
use append-abccare_iv, clear  
drop if R == 0 & RV == 1

// generate piatmath variable
egen piatmathABC  = rowmean(piat_math5y6m piat_math6y piat_math6y6m piat_math7y) if abc == 1
egen piatmathCARE = rowmean(wj_math5y6m wj_math6y wj_math7y6m) if abc == 0

gen piatmath = .
replace piatmath = piatmathABC 	if abc == 1
replace piatmath = piatmathCARE if abc == 0


local male0 if male == 0
local male1 if male == 1
local male2	


// invariance across regimes
forvalues i = 0/2 {
	foreach var of varlist si30y_inc_labor si30y_works_job {
	
		reg `var' piatmath m_ed0y years_30y si21y_inc_labor `male`i''
		predict r`var'_resid`i' if e(sample) == 1, resid
		summ    r`var'_resid`i'
		//replace r`var' = (r`var' - r(mean))/r(sd)
	}

}

keep id R RV male P Q dc_mo_pre* *_resid*

cd $data
saveold abccare-invariance-R-input, version(12) replace



