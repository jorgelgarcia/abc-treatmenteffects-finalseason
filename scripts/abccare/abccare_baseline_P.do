/* 
Project: 			ABC and CARE CBA
This file:			Construct table comparing control group selection into alt. preschool
Author:				Anna Ziff
Original date:		September 25, 2016
*/

// macros
global klmshare	:	env klmshare
global projects	:	env projects
global abc_dir 	= "${klmshare}/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv"
global output	= "${projects}/abc-treatmenteffects-finalseason/output"

local vars_to_compare m_ed0y m_age0y m_iq0y hrabc_index hh_sibs0y male birthyear apgar1 apgar5

local m_ed0y_lab 		"Mother's Yrs. of Edu."
local m_age0y_lab		"Mother's Age"
local m_iq0y_lab 		"Mother's IQ"
local hh_sibs0y_lab 	"Number of Siblings"
local hrabc_index_lab 	"HRI Score"
local birthyear_lab 	"Birth Year"
local male_lab			"Male"
local apgar1_lab 		"Apgar Score, 1 min."
local apgar5_lab 		"Apgar Score, 5 min."

cd $abc_dir
use append-abccare_iv, clear

drop if R == 0 & RV == 1
keep if R == 0

sum P

// t test
foreach v in `vars_to_compare' {
	ttest `v', by(P) unequal welch
	local `v'_p = r(p)
	local `v'_p : di %9.2f ``v'_p'
}

// collapase
local to_collapse
foreach v in `vars_to_compare' {
	local to_collapse `to_collapse' (mean) mean_`v'=`v' (sem) se_`v' = `v' (count) N_`v' = `v'
}

collapse `to_collapse', by(P)
drop if P == .

// make table
cd $output
cap file close ptable
file open ptable using "abccare_baseline_P.tex", write replace
file write ptable "\begin{tabular}{l c c}" _n
file write ptable "\toprule" _n
file write ptable "Characteristic & \mc{2}{c}{Control Substitution} \\" _n
file write ptable "& No & Yes \\" _n
file write ptable "& $ N=19 $ & $ N=55 $ \\" _n
file write ptable "\midrule" _n

foreach v in `vars_to_compare' {
	forval p = 0/1 {
		foreach stat in mean se N {
			sum `stat'_`v' if P == `p'
			local `stat'_`v'_`p' = r(mean)
			
			local `stat'_`v'_`p' : di %9.2f ``stat'_`v'_`p''
		}
	}
	
	file write ptable "``v'_lab' & `mean_`v'_0' & `mean_`v'_1' \\" _n
	file write ptable "			& (`se_`v'_0') & (`se_`v'_1')  \\" _n
}


file write ptable "\bottomrule" _n
file write ptable "\end{tabular}"
file close ptable
