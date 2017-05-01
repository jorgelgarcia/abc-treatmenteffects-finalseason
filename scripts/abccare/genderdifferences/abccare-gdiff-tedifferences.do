/*
Project: 	Treatment effects
Date:		April 27, 2017

This file:	Means of control group
*/

clear all
set more off

// parameters
set seed 1
global bootstraps 1
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
local vars 	p_inc3y6m p_inc12y p_inc15y p_inc21 hs30y si30y_univ_comp 	///
		years_30y si30y_works_job si30y_inc_labor ad34_fel ad34_mis 	///
		si34y_drugs si34y_sys_bp si34y_dia_bp si34y_hyper	
	
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

// calculate control means 
foreach v in `vars' {	
	forvalues s = 0/1 {
		qui sum `v' if male == `s' & R == 0 & apgar1 < . & apgar5 < . & hrabc_index < .
		local m`v'`name`s'' = r(mean)
		local m`v'`name`s'' = string(`m`v'`name`s''', "%9.3f")
	}
}



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
			reg `v' R if male == `s' //& apgar1 < . & apgar5 < . & hrabc_index < .
				
			matrix `v'tab`s' = e(b)
			matrix b`v'`s' = `v'tab`s'[1,1]
			matrix `name`s''`v' = (nullmat(`name`s''`v') \ b`v'`s')
			matrix colnames `name`s''`v' = `name`s''`v'
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
		local formatrix `formatrix' male`v', female`v',
	}
	else {
		local formatrix `formatrix' male`v', female`v'
	}
}

matrix all = `formatrix'
clear
svmat all, names(col)
qui gen n = _n

// inference
foreach v in `vars' {
	
	// locals for treatment effects
	sum male`v' if n == 1
	local te_male`v' = r(mean)
	sum female`v' if n == 1
	local te_female`v' = r(mean)
	
	// difference between male and female
	gen `v' = male`v' - female`v'
	local `v'control = `m`v'male' - `m`v'female'
	
	// point estimate of difference
	sum `v' if n == 1
	gen point_`v' = r(mean)
	local point_`v' = r(mean)
	
	// empirical mean of difference
	sum `v' if n > 1
	gen emp_`v' = r(mean)
	local emp_`v' = r(mean)
	// demean
	gen dm_`v' = `v' - emp_`v' if n > 1
	
	// compare with point
	gen diff_`v' = (abs(dm_`v') >= abs(point_`v')) if n > 1
	sum diff_`v'
	gen p2_`v' = r(mean)
	local p2_`v' = r(mean)
}

// prepare for table
foreach v in `vars' {
	foreach j in te_male`v' te_female`v' m`v'male m`v'female emp_`v' point_`v' p2_`v' {
		local `j' = string(``j'', "%12.3fc")
	}
}

// make table

file open tabfile using "${output}/abccare-gdiff-treatmenteffects-1.tex", replace write
file write tabfile "\begin{tabular}{l l c c c c c c c c c}" _n
file write tabfile "\toprule" _n
file write tabfile "\mc{1}{c}{Category} & \mc{1}{c}{Variable} & \mc{1}{c}{Age} & \mc{2}{c}{Female} & \mc{2}{c}{Male} & \mc{2}{c}{Difference} & \mc{2}{c}{Rank Sign Test} \\" _n
file write tabfile "\cmidrule(lr){4-5} \cmidrule(lr){6-7} \cmidrule(lr){8-9} \cmidrule(lr){10-11}" _n
file write tabfile "			&			&		& $\overbar{Y}_C$ & Effect & $\overbar{Y}_C$ & Effect & $\overbar{Y}_C$ & Effect & $\overbar{Y}_C$ & Effect \\" _n
file write tabfile "\midrule" _n	

foreach v in `vars' {
	

	file write tabfile "${cat_`v'} & ${name_`v'} & ${age_`v'} & `m`v'female' & `te_female`v'' & `m`v'male' & `te_male`v'' & diff control & diff treatment & pvalue control & pvalue treatment \\" _n
}
		
file write tabfile "\bottomrule" _n
file write tabfile "\end{tabular}" _n
file write tabfile "% This file generated by: abccare-cba/scripts/abccare/genderdifferences/abccare-gdiff-tedifferences.do" _n
file close tabfile

