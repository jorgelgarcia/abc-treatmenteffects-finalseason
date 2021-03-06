/*
Project: 	Treatment effects
Date:		April 27, 2017

This file:	Means of control group
*/

clear all
set more off

// parameters
set seed 1
global bootstraps 100
global quantiles 30

// macros
global projects		: env projects
global klmshare		: env klmshare
global klmmexico	: env klmMexico

// filepaths
global data	   	= "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv"
global scripts    	= "$projects/abccare-cba/scripts/"
global output      	= "$projects/abccare-cba/output/"

local name0 female
local name1 male
local vars 	iq5y iq8y ach8y achy12y ibr_task1y ibr_task1y6m ibr_sociab1y ibr_sociab1y6m p_inc3y6m p_inc12y p_inc15y p_inc21 hs30y si30y_univ_comp 	///
		years_30y si30y_works_job si30y_inc_labor ad34_fel ad34_mis 	///
		si34y_drugs si34y_sys_bp si34y_dia_bp si34y_hyper	

global name_iq5y IQ
global name_iq8y 
global name_ach8y Achievement
global name_achy12y 
global name_ibr_task1y Task orientation
global name_ibr_sociab1y Sociability
global name_ibr_task1y6m
global name_ibr_sociab1y6m	
global name_p_inc3y6m Parental Labor Income
global name_p_inc12y 
global name_p_inc15y 
global name_p_inc21
global name_hs30y Graduated High School
global name_si30y_univ_comp Graduated 4-year College
global name_years_30y Years of Education
global name_si30y_works_job Employed
global name_si30y_inc_labor Labor Income
global name_ad34_fel Total Felony Arrests
global name_ad34_mis Total Misdemeanor Arrests
global name_si34y_drugs Self-reported drug user
global name_si34y_sys_bp Systolic Blood Pressure (mm Hg)
global name_si34y_dia_bp Diastolic Blood Pressure (mm Hg)
global name_si34y_hyper	Hypertension

global age_iq5y 5
global age_iq8y 8
global age_ach8y 8
global age_achy12y 12
global age_ibr_task1y 1
global age_ibr_sociab1y 1
global age_ibr_task1y6m 1.5
global age_ibr_sociab1y6m 1.5
global age_p_inc3y6m 3.5
global age_p_inc12y 12
global age_p_inc15y 15
global age_p_inc21 21
global age_hs30y 30
global age_si30y_univ_comp 30	
global age_years_30y  30
global age_si30y_works_job  30
global age_si30y_inc_labor  30
global age_ad34_fel Mid-30s
global age_ad34_mis Mid-30s	
global age_si34y_drugs Mid-30s
global age_si34y_sys_bp Mid-30s
global age_si34y_dia_bp Mid-30s
global age_si34y_hyper	Mid-30s

global cat_iq5y Cognitive
global cat_ibr_task1y Social-emotional
global cat_p_inc3y6m Parental Income
global cat_p_inc12y 
global cat_p_inc15y 
global cat_p_inc21
global cat_hs30y Education
global cat_si30y_univ_comp 	
global cat_years_30y 
global cat_si30y_works_job Labor Income
global cat_si30y_inc_labor 
global cat_ad34_fel Crime
global cat_ad34_mis 	
global cat_si34y_drugs Health
global cat_si34y_sys_bp 
global cat_si34y_dia_bp 
global cat_si34y_hyper	

// data
cd $data
use append-abccare_iv, clear

drop if R == 0 & RV == 1

// treatment effects
forvalues b1 = 0/$bootstraps {
	di "`b1'"
	preserve
	
	if `b1' > 0 {
		bsample
	}
	
	foreach v in `vars' {
		
		// by gender
		forvalues s = 0/1 {
			qui sum `v' if male == `s' & R == 0 & apgar1 < . & apgar5 < . & hrabc_index < .
			matrix `v'cmean`s'`b1' = r(mean)
			matrix `name`s''`v'cmean = (nullmat(`name`s''`v'cmean) \ `v'cmean`s'`b1')
			matrix colnames `name`s''`v'cmean = `name`s''`v'cmean
			
			qui reg `v' R if male == `s' 
				
			matrix `v'tab`s' = e(b)
			matrix `v'te`s'`b1' = `v'tab`s'[1,1]
			matrix `name`s''`v'te = (nullmat(`name`s''`v'te) \ `v'te`s'`b1')
			matrix colnames `name`s''`v'te = `name`s''`v'te
		}
	}
	restore
}

// bring to data
local numvars : word count `vars'
local n = 0
foreach v in `vars' {
	local n = `n' + 1
	if `n' < `numvars' {
		local formatrix `formatrix' male`v'cmean, female`v'cmean, male`v'te, female`v'te,
	}
	else {
		local formatrix `formatrix' male`v'cmean, female`v'cmean, male`v'te, female`v'te
	}
}

matrix all = `formatrix'
clear
svmat all, names(col)
qui gen n = _n

foreach v in `vars' {
	foreach t in cmean te {
	
		// rank sum p-values
		signrank male`v'`t' = female`v'`t'
		local p`v'`t' = 2 * normprob(-abs(r(z)))
		local p`v'`t' = string(`p`v'`t'', "%9.3fc")
		if "`p`v'`t''" == "0.000" {
			local p`v'`t' "$ < $ 0.001"
		}
		
		// difference
		gen diff_`t'`v' = male`v'`t' - female`v'`t' if n == 1
		sum diff_`t'`v'
		if r(mean) < 1000 {
			local diff_`t'`v' = string(r(mean), "%9.3fc")
		}
		else {
			local diff_`t'`v' = string(r(mean), "%9.0fc")
		}
		// point estimates
		forvalues s = 0/1 {
			sum `name`s''`v'`t' if n == 1
			if r(mean) < 1000 {
				local po_`t'`v'`name`s'' = string(r(mean), "%9.3fc")
			}
			else {
				local po_`t'`v'`name`s'' = string(r(mean), "%9.0fc")
			}
		}
	}
}




// make table

file open tabfile using "${output}/abccare-gdiff-treatmenteffects-1.tex", replace write
file write tabfile "\begin{tabular}{l l c c c c r c c c r}" _n
file write tabfile "\toprule" _n
file write tabfile "\mc{1}{c}{Category} & \mc{1}{c}{Variable} & \mc{1}{c}{Age} & \mc{4}{c}{\textbf{Control Mean}} & \mc{4}{c}{\textbf{Treatment Effect}} \\" _n
file write tabfile "\cmidrule(lr){4-7} \cmidrule(lr){8-11}" _n
file write tabfile "&	& & Male & Female & Difference & $ p $ -value & Male & Female & Difference & $ p $ -value \\" _n
file write tabfile "\midrule" _n	

foreach v in `vars' {
	

	file write tabfile "${cat_`v'} & ${name_`v'} & ${age_`v'} & `po_cmean`v'male' & `po_cmean`v'female' & `diff_cmean`v'' & `p`v'cmean' & `po_te`v'male' & `po_te`v'female' & `diff_te`v'' & `p`v'te' \\" _n
}
		
file write tabfile "\bottomrule" _n
file write tabfile "\end{tabular}" _n
file write tabfile "% This file generated by: abccare-cba/scripts/abccare/genderdifferences/abccare-gdiff-tedifferences.do" _n
file close tabfile

