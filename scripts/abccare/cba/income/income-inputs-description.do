/*

Project:		ABC CBA
Script:			Table describing inputs for labor projections
Author:			Anna Ziff (aziff@uchicago.edu)
Original date:	February 1, 2018

*/

// filepaths
global dataabccare   = "${klmshare}/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
global data_dir      = "${projects}/abccare-cba/scripts/abccare/cba/income/rslt/projections/`file_specs'"
global incomeresults = "${klmmexico}/abccare/income_projections/current"
global output        = "${projects}/abccare-cba/output/"

// data
cd $dataabccare
use append-abccare_iv, clear

drop if R == 0 & RV == 1

// generate piatmath variable
egen piatmathABC = rowmean(piat_math5y6m piat_math6y piat_math6y6m piat_math7y) if abc == 1
egen piatmathCARE = rowmean(wj_math5y6m wj_math6y wj_math7y6m) if abc == 0

gen piatmath = .
replace piatmath = piatmathABC 	if abc == 1
replace piatmath = piatmathCARE if abc == 0

// calculate statistics of interest
local varlist piatmath years_30y si21y_inc_labor

foreach v in `varlist' {
	
	forvalues sex = 0/1 {
	
		reg `v' R if male == `sex'
		matrix `v's`sex' = e(b)
		
		// treatment effect
		global `v'_s`sex'_te = `v's`sex'[1,1]
		global `v'_s`sex'_te : di %9.2fc ${`v'_s`sex'_te}
		
		// control mean
		global `v'_s`sex'_cmean = `v's`sex'[1,2]
		global `v'_s`sex'_cmean : di %9.2fc ${`v'_s`sex'_cmean}
		
		// standard error
		matrix `v's`sex'V = e(V)
		global `v'_s`sex'_se = `v's`sex'V[1,1]
		global `v'_s`sex'_se = sqrt(${`v'_s`sex'_se})
		global `v'_s`sex'_se : di %9.2fc ${`v'_s`sex'_se}
	
	}
}

// make table
cd $output
file open tabfile using "income-inputs-description.tex", write replace
file write tabfile "\begin{tabular}{lcccc}" _n
file write tabfile "\toprule" _n
file write tabfile "& \mc{2}{c}{Females} & \mc{2}{c}{Males} \\" _n
file write tabfile "\cmidrule(lr){2-3} \cmidrule(lr){4-5}" _n
file write tabfile "& Control & Average & Control & Average  \\" _n
file write tabfile "& Mean & Treatment Effect & Mean & Treatment Effect  \\" _n
file write tabfile "\midrule" _n
file write tabfile "Math Scores & $ $piatmath_s0_cmean $  & $ $piatmath_s0_te $ & $ $piatmath_s1_cmean $ & $ $piatmath_s1_te $ \\" _n
file write tabfile "(ages 5-7)			& 						& ($ $piatmath_s0_se $) & & ($  $piatmath_s1_se $) \\" _n
file write tabfile "Years of Education & $ $years_30y_s0_cmean $ & $ $years_30y_s0_te $ & $ $years_30y_s1_cmean $ & $ $years_30y_s1_te $ \\" _n
file write tabfile "(age 30)			& 						& ($ $years_30y_s0_se $) & & ($ $years_30y_s1_se $) \\" _n
file write tabfile "Labor Income  & $ $si21y_inc_labor_s0_cmean $ & $ $si21y_inc_labor_s0_te $ & $ $si21y_inc_labor_s1_cmean $ & $ $si21y_inc_labor_s1_te $ \\" _n
file write tabfile "(age 21)			& 						& ($ $si21y_inc_labor_s0_se $) & & ($ $si21y_inc_labor_s1_se $) \\" _n
file write tabfile "\bottomrule" _n
file write tabfile "\end{tabular}" _n
file write tabfile "% This file produced using scripts/abccare/cba/labor/income-inputs-description.do"
file close tabfile
