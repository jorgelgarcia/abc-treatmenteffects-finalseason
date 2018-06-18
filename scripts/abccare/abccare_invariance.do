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
cd $dataabccare
use append-abccare_iv, clear  
drop if R == 0 & RV == 1

// generate piatmath variable
egen piatmathABC  = rowmean(piat_math5y6m piat_math6y piat_math6y6m piat_math7y) if abc == 1
egen piatmathCARE = rowmean(wj_math5y6m wj_math6y wj_math7y6m) if abc == 0

gen piatmath = .
replace piatmath = piatmathABC 	if abc == 1
replace piatmath = piatmathCARE if abc == 0

// invariance across regimes
foreach var of varlist si30y_works_job si30y_inc_labor {
	reg `var' R m_ed0y piatmath years_30y si21y_inc_labor

	// distributions of residuals 
	// replace `var' = log(`var' + 1)
	reg `var' piatmath m_ed0y years_30y si21y_inc_labor 
	predict r`var'inc_resid if e(sample) == 1, resid
	summ    r`var'inc_resid
	replace r`var' = (r`var' - r(mean))/r(sd)
	ttest r`var', unequal by(R)
	ksmirnov r`var', by(R)
}
summ si30y_inc_labor if R == 0





// invariance across samples
gen K = 1

// bring CNLSY
cd $datacnlsyw
append using cnlsy-abc-match.dta
replace K = 0 if K == .

foreach num of numlist 0 1 {
reg si30y_inc_labor K m_ed0y piatmath years_30y si21y_inc_labor if male == `num'

// distributions of residuals 
// replace si30y_inc_labor = log(si30y_inc_labor + 1)
reg si30y_inc_labor m_ed0y piatmath years_30y si21y_inc_labor   if male == `num'
predict inc_resid if e(sample) == 1, resid
summ    inc_resid
replace inc_resid = (inc_resid - r(mean))/r(sd)
ttest inc_resid, unequal by(K)
ksmirnov inc_resid, by(K) exact

drop    inc_resid
}

summ si30y_inc_labor if K == 1 & male == 0 
summ si30y_inc_labor if K == 1 & male == 1 
summ si30y_inc_labor if K == 0 & male == 0 
summ si30y_inc_labor if K == 0 & male == 1 










