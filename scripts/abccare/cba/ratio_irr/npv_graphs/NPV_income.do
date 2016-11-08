

// macros
global klmshare		: env klmshare
global klmMexico 	: env klmMexico
global projects 	: env projects

local dr = 0 						// discount rate 
local file_specs	pset1_mset3 	// for income

global flows		= "${projects}/abc-treatmenteffects-finalseason/scripts/abccare/cba/ratio_irr/flows"
global save_data 	= "${klmMexico}/abccare/NPV/current"
global income_data 	= "${projects}/abc-treatmenteffects-finalseason/scripts/abccare/cba/income/rslt/projections"
global abc_data		= "${projects}/abc-treatmenteffects-finalseason/data/abccare/extensions/fam-merge"
global ate_data		= "${klmshare}/Data_Central/Abecedarian/data/ABC-CARE/extensions/outcomes_ate"
global proj_dir 	= "${projects}/abc-treatmenteffects-finalseason/scripts/abccare/cba/ratio_irr/npv_graphs"

// produce point estimate and vector of NPV
foreach loop in point /*vector*/ {

	// income

	local transfer_max 		59
	local labor_max 		47

	local transfer_max_age	79
	local labor_max_age		67

	cd "$income_data/`file_specs'"
	foreach type in labor transfer {
		if "`type'" == "transfer" {
			cd "../transfer_`file_specs'"
		}
		insheet using "`type'_proj_combined_`file_specs'_pooled.csv", clear 
		
		if "`loop'" == "point" {
			keep if adraw == 0
		}
		else {
			drop if adraw == 100
		}

		// rename varaibles to be by age
		local age = 22
		forvalues i = 3/10 {
			rename v`i' `type'_c`age'
			local age = `age' + 1
		}
		local age = 31
		forvalues i = 11/``type'_max' {
			rename v`i' `type'_c`age'
			local age = `age' + 1
		}
	
		if "`type'" == "transfer" {
			forvalues a = 22/79 {
				cap rename `type'_c`a'		raw_`type'_c`a'
				cap gen `type'_c`a' =		raw_`type'_c`a' * `dr' * -1 
			
			}
		}
	
		gen `type'_c30 = .
	
		keep id adraw `type'_c* 
		
		tempfile save_`type'_`loop'
		save `save_`type'_`loop''
		
	
	}

	// health

	
	
	if "`loop'" == "point" {
		cd $proj_dir
		insheet using "health_for_NPV.csv", clear
	}
	
	else {
		cd $abc_data
		insheet using "abc-fam-merge.csv", clear
		sort id adraw
	}
	
	drop if r == 0 & rv == 1

	keep id r male adraw diclaim* ssclaim* ssiclaim* qaly* health_private* health_public*

	forvalues a = 8/108 {
		rename ssclaim`a' 			raw_ssclaim`a'
		gen ssclaim`a' = 			raw_ssclaim`a' * 1.02 * 12 * 1228 * `dr' * -1
	
		rename ssiclaim`a' 			raw_ssiclaim`a'
		gen ssiclaim`a' = 			raw_ssiclaim`a' * 1.02 * 12 * 901.5 * `dr' * -1
	
		rename health_private`a' 	raw_health_private`a'
		gen health_private`a' = 	raw_health_private`a' * 1.1 * -1
	
		rename health_public`a'		raw_health_public`a'
		gen health_public`a' =		raw_health_public`a' * 1.1 * (1 + `dr') * -1
	
		rename qaly`a' 				raw_qaly`a'
		gen qaly`a' =				raw_qaly`a' * 150000
	
		rename diclaim`a'			raw_diclaim`a'
		* need to calculate cost of DI claim
	
	}

	tempfile save_raw_health_`loop'
	save `save_raw_health_`loop''
	
	// diclaim

	/*
	insheet using "di_claim.csv", clear

	forvalues a = 20/65 {
		foreach s in p m f {
			sum `s' if age == `a'
			local `s'_`a' = r(mean)
		}
	}

	use `save_raw_health', clear

	*/


	// batch

	cd $ate_data
	insheet using "outcomes_ate.csv", clear

	drop if r == 0 & rv == 1

	keep id cccostprivate* cccostpublic* educost* ip_p_inc* private_crime* public_crime*

	forvalues a = 1/5 {
		rename cccostprivate`a'		raw_cccostprivate`a'
		gen cccostprivate`a' =		raw_cccostprivate`a' * -1
	
		rename cccostpublic`a'		raw_cccostpublic`a'
		gen cccostpublic`a'	=		raw_cccostpublic`a' * (1 + `dr') * -1
	}

	forvalues a = 0/26 {
		rename educost`a'			raw_educost`a'
		gen educost`a' =			raw_educost`a' * -1
	
		if `a' <= 18 {
			replace educost`a' = educost`a' * (1 + `dr')
		}
	}

	forvalues a = 6/50 {
		rename private_crime`a'		raw_private_crime`a'
		gen private_crime`a' = 		raw_private_crime`a' * -1
	
		rename public_crime`a'		raw_public_crime`a'
		gen public_crime`a' = 		raw_public_crime`a' * (1 + `dr') * -1
	}
	
	if "`loop'" == "point" {
		tempfile save_batch_`loop'
		save `save_batch_`loop''
	}
	
	else {
		gen adraw = 0
		
		tempfile batch_adraw0
		save `batch_adraw0'
		
		tempfile save_batch_`loop'
		save `save_batch_`loop''
	
		forval i = 1/99 {
			use `batch_adraw0', clear
			replace adraw = `i'
			
			append using `save_batch_`loop''
			
			tempfile save_batch_`loop'
			save `save_batch_`loop''
		}
		
	}

	// merge all parts together
	if "`loop'" == "point" {
		merge 1:1 id using `save_raw_health_`loop'', nogen
		merge 1:1 id using `save_labor_`loop'', nogen
		merge 1:1 id using `save_transfer_`loop'', nogen
	}
	else {
		merge m:m id adraw using `save_raw_health_`loop'', nogen
		merge m:m id adraw using `save_labor_`loop'', nogen
		merge m:m id adraw using `save_transfer_`loop'', nogen
	}

	// discount
	local components 	labor_c transfer_c ///
					health_private health_public qaly ssiclaim ssclaim /* diclaim */ ///
					cccostprivate cccostpublic educost /*private_crime public_crime*/ ip_p_inc

	local labor_c_min_age 			22
	local labor_c_max_age 			67 //67

	local transfer_c_min_age 		22
	local transfer_c_max_age 		79 //79

	local health_private_min_age 	8
	local health_private_max_age 	108 //108

	local health_public_min_age 	8
	local health_public_max_age 	108 //108

	local qaly_min_age 				8
	local qaly_max_age 				108 //108

	local ssiclaim_min_age 			8
	local ssiclaim_max_age 			108 //108

	local ssclaim_min_age 			8
	local ssclaim_max_age 			108 //108

	local cccostprivate_min_age		1
	local cccostprivate_max_age		5

	local cccostpublic_min_age		1
	local cccostpublic_max_age		5

	local educost_min_age			0
	local educost_max_age			26

	local private_crime_min_age		6
	local private_crime_max_age		50 //50

	local public_crime_min_age		6
	local public_crime_max_age		50 //50

	local ip_p_inc_min_age			0
	local ip_p_inc_max_age			21

	
	// discount rate: 3%
	foreach c in `components' {
		local vars_`c'
		forvalues a = ``c'_min_age'/``c'_max_age' {
			gen D`c'`a' = `c'`a'/(1.03^`a')
			local vars_`c' `vars_`c'' D`c'`a'
		}
		di "`vars_`c''"
	}
	
	preserve
		* special output for labor
		cd $save_data
		keep id r male adraw labor_c*
	
		collapse labor_c*, by(r male adraw)
	
		save labor_r-male-draw, replace
	restore
	preserve
		cd $save_data
		* special output for QALYs
		keep id r male adraw qaly*
	
		collapse qaly*, by(r male adraw)
	
		save qaly_r-male-draw, replace
	
	restore


	// sum over each component and average
	
	if "`loop'" == "point" {
	
		cap file close NPV
		file open NPV using "~/Desktop/indivual_NPV_point.tex", write replace
		file write NPV "\begin{table}" _n
		file write NPV "\begin{center}" _n
		file write NPV "\begin{tabular}{ccc}" _n
		file write NPV "\toprule" _n
		file write NPV "Component & Control & Treatment \\" _n
		file write NPV "\midrule" _n
		
	}

	foreach c in `components' {
		egen total_`c' = rowtotal(`vars_`c''), missing
	
		sum total_`c' if r == 0
		local `c'_R0 = r(mean)
		local `c'_R0 : di %9.2f ``c'_R0' 
	
		sum total_`c' if r == 1
		local `c'_R1 = r(mean)
		local `c'_R1 : di %9.2f ``c'_R1'
		
		if "`loop'" == "point" {
		
			file write NPV "`c' & ``c'_R0' & ``c'_R1' \\" _n
			
		}
	}

	// aggregate NPV
	gen total_NPV = 0
	foreach c in `components' {
		replace total_NPV = total_NPV + total_`c' if total_`c' < .
	}

	if "`loop'" == "point" {
		sum total_NPV if r == 0
		local total_R0 = r(mean)
		local total_R0 : di %9.2f `total_R0' 
		
		sum total_NPV if r == 1
		local total_R1 = r(mean)
		local total_R1 : di %9.5f `total_R1'

		file write NPV "TOTAL & `total_R0' & `total_R1' \\" _n

		file write NPV "\bottomrule" _n
		file write NPV "\end{tabular}{ccc}" _n
		file write NPV "\end{center}" _n
		file write NPV "\end{table}" _n
		file close NPV
	}

}

// output vector of means by bootstrap

keep id adraw r total*


foreach c in `components' NPV {
	forvalues i = 0/1 {
		
		forvalues bs = 0/99 {
			sum total_`c' if r == `i' & adraw == `bs'
			gen meanR`i'_`c'`bs' = r(mean) 
		}
	}
}

gen N = _n
keep if N == 1
keep meanR?_NPV* meanR?_labor_c* N

local vars_to_reshape meanR0_NPV meanR0_labor_c meanR1_NPV meanR1_labor_c

reshape long `vars_to_reshape', i(N) j(adraw)
drop N

saveold NPV_vectors_age108, replace
