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

local vars_to_compare m_ed0y m_work0y m_age0y m_iq0y f_home0y p_inc0y hrabc_index hh_sibs0y male birthyear apgar1 apgar5

local m_ed0y_lab 		"Mother's Yrs. of Edu."
local m_age0y_lab		"Mother's Age"
local m_iq0y_lab 		"Mother's IQ"
local m_work0y_lab		"Mother Works"
local hh_sibs0y_lab 	"Number of Siblings"
local hrabc_index_lab 	"HRI Score"
local birthyear_lab 	"Birth Year"
local male_lab			"Male"
local apgar1_lab 		"Apgar Score, 1 min."
local apgar5_lab 		"Apgar Score, 5 min."
local p_inc0y_lab		"Parental Income"
local f_home0y_lab		"Father Present"


local KEEP0				keep if male == 0
local KEEP1				keep if male == 1
local KEEP2

cd $abc_dir
use append-abccare_iv, clear

drop if R == 0 & RV == 1
keep if R == 0

sum P

forval sex = 0/2 {
preserve

	`KEEP`sex''
	
	// get N
	sum P if P == 0
	local N0_sex`sex' = r(N)
	sum P if P == 1
	local N1_sex`sex' = r(N)

	// t test
	foreach v in `vars_to_compare' {
		ttest `v', by(P) unequal welch
		local `v'_p`sex' = r(p)
		local `v'_p`sex' : di %9.2f ``v'_p`sex''
	}

	// collapase
	local to_collapse
	foreach v in `vars_to_compare' {
		local to_collapse `to_collapse' (mean) mean_`v'=`v' (sem) se_`v' = `v' (count) N_`v' = `v'
	}

	collapse `to_collapse', by(P)
	drop if P == .
	
	foreach v in `vars_to_compare' {
		forval p = 0/1 {
			foreach stat in mean se N {
				sum `stat'_`v' if P == `p'
				local `stat'_`v'_`p'`sex' = r(mean)
				local `stat'_`v'_`p'`sex' : di %9.2f ``stat'_`v'_`p'`sex''	
			}
			if ``v'_p`sex'' <= 0.1 {
				local mean_`v'_`p'`sex' \textbf{`mean_`v'_`p'`sex''}
			}
		}
	}
	
restore
}

	// make table
	cd $output
	cap file close ptable
	file open ptable using "abccare_baseline_P.tex", write replace
	file write ptable "\begin{tabular}{l c c c c c c c c c}" _n
	file write ptable "\toprule" _n
	file write ptable "Characteristic & \mc{3}{c}{Females} & \mc{3}{c}{Males} & \mc{3}{c}{Pooled}\\" _n
	file write ptable "\cmidrule(lr){2-4} \cmidrule(lr){5-7} \cmidrule(lr){8-10}" _n
	file write ptable "& \mc{2}{c}{Control Substitution} & $ p $ -value & \mc{2}{c}{Control Substitution} & $ p $ -value & \mc{2}{c}{Control Substitution} & $ p $ -value \\" _n
	file write ptable "& No & Yes & & No & Yes & & No & Yes &\\" _n
	file write ptable "& $ N =`N0_sex0' $ & $ N =`N1_sex0' $ & & $ N =`N0_sex1' $ &  $ N =`N1_sex1' $ & & $ N =`N0_sex2' $ & $ N =`N1_sex2' $ & \\" _n
	file write ptable "\midrule" _n

	foreach v in `vars_to_compare' {
	
		if "`v'" == "male" {
			file write ptable "``v'_lab' & . & . & . & . & . & . & `mean_`v'_02' & `mean_`v'_12' & ``v'_p2' \\" _n
			file write ptable "&  & & & &  & & (`se_`v'_02') & (`se_`v'_12')  & \\" _n
		}
		
		else {
	
			file write ptable "``v'_lab' & `mean_`v'_00' & `mean_`v'_10' & ``v'_p0' & `mean_`v'_01' & `mean_`v'_11' & ``v'_p1' & `mean_`v'_02' & `mean_`v'_12' & ``v'_p2' \\" _n
			file write ptable "	& $ (`se_`v'_00') $ & $ (`se_`v'_10') $  & & $ (`se_`v'_01') $ & $ (`se_`v'_11') $ & & $ (`se_`v'_02') $ & $ (`se_`v'_12') $  & \\" _n
		}
		
	}


	file write ptable "\bottomrule" _n
	file write ptable "\end{tabular}"
	file close ptable

