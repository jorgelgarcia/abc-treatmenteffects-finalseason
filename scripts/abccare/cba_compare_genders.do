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
global est_dir	= "${projects}/abc-treatmenteffects-finalseason/scripts/abccare/cba/ratio_irr/rslt/tables/"
global output	= "${projects}/abc-treatmenteffects-finalseason/output"

// bring in estimates
foreach folder in type2 type5 type8 {

	cd $est_dir
	cd `folder'
	
	foreach stat in ratio irr {
		insheet using `stat'_mean.csv, clear
		tempfile `folder'`stat'_rslt
		save ``folder'`stat'_rslt'
	}

	foreach t in irr ratios {
		insheet using all_`t'_`folder'.csv, clear
		rename v1 sex
		rename v2 adraw
		rename v3 ddraw
		rename v4 `t'
		
		tempfile `t'
		save ``t''
	}

	merge 1:1 sex adraw ddraw using `irr', nogen


	sort sex
	by sex: gen N = _n
	drop adraw ddraw
	gen male = .
	replace male = 1 if sex == "m"
	replace male = 0 if sex == "f"

	sum ratios, detail
	drop if ratios > r(p95) | ratios < r(p5)
	drop if irr < 0

	ttest ratios, by(male) welch
	forvalues sex = 1/2 {
		foreach stat in mu sd N {
			local `stat'`folder'_ratio_`sex' = r(`stat'_`sex')
			local `stat'`folder'_ratio_`sex' : di %9.2f ``stat'`folder'_ratio_`sex''
		}
	}
	
	ttest irr, by(male) welch
	forvalues sex = 1/2 {
		foreach stat in mu sd N {
			local `stat'`folder'_irr_`sex' = r(`stat'_`sex')
			local `stat'`folder'_irr_`sex' : di %9.2f ``stat'`folder'_irr_`sex''
		}
		local se`folder'_ratio_`sex' = `sdtype2_ratio_`sex''/sqrt(`Ntype2_ratio_`sex'')
		local se`folder'_irr_`sex' = `sdtype2_irr_`sex''/sqrt(`Ntype2_irr_`sex'')
		local se`folder'_ratio_`sex' : di %9.2f `se`folder'_ratio_`sex''
		local se`folder'_irr_`sex' : di %9.2f `se`folder'_irr_`sex''
	}
	local p`folder' = r(p)
	
	use ``folder'irr_rslt', clear
	sum v2 if v1 == "f"
	local rslt_irr_f`folder' = r(mean)
	local rslt_irr_f`folder' : di %9.2f `rslt_irr_f`folder''
	if `p`folder'' <= 0.1 {
		local rslt_irr_f`folder' \textbf{`rslt_irr_f`folder''}
	}
	
	sum v2 if v1 == "m"
	local rslt_irr_m`folder' = r(mean)
	local rslt_irr_m`folder' : di %9.2f `rslt_irr_m`folder''
	if `p`folder'' <= 0.1 {
		local rslt_irr_m`folder' \textbf{`rslt_irr_m`folder''}
	}
	
	use ``folder'ratio_rslt', clear
	sum v2 if v1 == "f"
	local rslt_ratio_f`folder' = r(mean)
	local rslt_ratio_f`folder' : di %9.2f `rslt_ratio_f`folder''
	if `p`folder'' <= 0.1 {
		local rslt_ratio_f`folder' \textbf{`rslt_ratio_f`folder''}
	}
	
	sum v2 if v1 == "m"
	local rslt_ratio_m`folder' = r(mean)
	local rslt_ratio_m`folder' : di %9.2f `rslt_ratio_m`folder''
	if `p`folder'' <= 0.1 {
		local rslt_ratio_m`folder' \textbf{`rslt_ratio_m`folder''}
	}
	
	

	
	
	
}

// make table
cap file close sig
file open sig using "${output}/cba_compare_genders.tex", write replace
file write sig "\begin{tabular}{l c c c c}" _n
file write sig "\toprule" _n
file write sig "& \mc{2}{c}{B/C} & \mc{2}{c}{IRR} \\" _n
file write sig "\cmidrule(lr){2-3} \cmidrule(lr){4-5} \\" _n
file write sig "& Females & Males & Females & Males \\" _n
file write sig "\midrule \\" _n
file write sig "Baseline & `rslt_ratio_ftype2' & `rslt_ratio_mtype2' & `rslt_irr_ftype2' & `rslt_irr_mtype2' \\" _n
file write sig "Relative to Staying at Home & `rslt_ratio_ftype5' & `rslt_ratio_mtype5' & `rslt_irr_ftype5' & `rslt_irr_mtype5' \\" _n
file write sig "Relative to Alternative Preschools & `rslt_ratio_ftype8' & `rslt_ratio_mtype8' & `rslt_irr_ftype8' & `rslt_irr_mtype8' \\" _n
file write sig "\bottomrule" _n
file write sig "\end{tabular}" _n
file close sig




