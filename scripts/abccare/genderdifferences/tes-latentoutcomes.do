/*
Project: 	Treatment effects
Date:		April 27, 2017

This file:	Means of control group
*/

clear all
set maxvar 30000
set matsize 11000
set more off

// parameters
set seed 1
global bootstraps 25
global maxtries 20
global quantiles 30

// macros
global projects		: env projects
global klmshare		: env klmshare
global klmmexico	: env klmMexico

// filepaths
global data	   	= "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv"
global scripts    	= "$projects/abccare-cba/scripts/"
global output      	= "$projects/abccare-cba/output/"

cd $data
use append-abccare_iv, clear
drop if R == 0 & RV == 1
gen fakeR = R
recode fakeR (0=1) (1=0)

cd ${scripts}/abccare/genderdifferences

	include abccare-reverse
	//include abccare-112-outcomes
	
	
local categories pinc edu emp crime hyp

local pinc_name 	Parental Income Latent
local edu_name 		Education Latent
local emp_name 		Employment Latent
local crime_name 	Crime Latent
local hyp_name 		Hypertension Latent

local pinc_age 		1.5 to 21
local edu_age 		21 to 30
local emp_age 		21 to 30
local crime_age 	30 to Mid-30s
local hyp_age 		Mid-30s
	
global pinclatent 		p_inc1y6m p_inc2y6m p_inc3y6m p_inc4y6m p_inc8y p_inc12y p_inc15y p_inc21y
global edulatent 		sch_hs30y si30y_techcc_att si30y_univ_comp years_30y ever_sped tot_sped ever_ret tot_ret
global emplatent 		si30y_works_job si21y_inc_labor si30y_inc_labor si21y_inc_trans_pub si30y_inc_trans_pub
global crimelatent 		ad34_fel ad34_mis si30y_adlt_totinc
global hyplatent 		si34y_sys_bp si34y_dia_bp si34y_prehyper si34y_hyper

global carepinclatent 		p_inc1y6m p_inc2y6m p_inc3y6m p_inc4y6m
global careemplatent 		si30y_works_job si30y_inc_labor si30y_inc_trans_pub



# delimit ; 
keep 	id R RV male P m_age0y	apgar1 apgar5 abc hrabc_index cohort prem_birth	
		m_ed0y hh_sibs0y fakeR
		$pinclatent $edulatent $emplatent $crimelatent $hyplatent ;


local toimpute 	p_inc1y6m p_inc2y6m p_inc3y6m p_inc4y6m p_inc8y p_inc12y p_inc15y p_inc21y 
				si30y_univ_comp 
				si21y_inc_labor si30y_inc_labor si21y_inc_trans_pub si30y_inc_trans_pub 
				ad34_fel ad34_mis si34y_dia_bp 
				si34y_sys_bp si34y_prehyper si34y_hyper
;
# delimit cr

global p_inc1y6m_impute				m_age0y	apgar1	cohort
global p_inc2y6m_impute				m_age0y	apgar1	cohort
global p_inc3y6m_impute				m_age0y	apgar1	cohort
global p_inc4y6m_impute				hrabc_index	apgar1	cohort
global p_inc8y_impute				hrabc_index	apgar1	cohort
global p_inc12y_impute				hrabc_index	apgar1	cohort
global p_inc15y_impute				apgar5	prem_birth	hh_sibs0y
global p_inc21y_impute				hrabc_index	apgar1	cohort
	
global si30y_univ_comp_impute			apgar1	apgar5	cohort

global si21y_inc_labor_impute			hrabc_index	apgar1	cohort
global si30y_inc_labor_impute			m_ed0y	apgar5	cohort
global si21y_inc_trans_pub_impute		hrabc_index	apgar1	cohort
global si30y_inc_trans_pub_impute		m_ed0y	apgar5	cohort

global ad34_fel_impute				apgar1	apgar5	cohort
global ad34_mis_impute				apgar1	apgar5	cohort
			
global si34y_dia_bp_impute			apgar1	prem_birth	hh_sibs0y
global si34y_sys_bp_impute			apgar1	prem_birth	hh_sibs0y
global si34y_prehyper_impute			apgar1	prem_birth	hh_sibs0y	
global si34y_hyper_impute			apgar1	prem_birth	hh_sibs0y


mi set wide
mi register imputed `toimpute' P m_age0y apgar1 apgar5 abc hrabc_index cohort prem_birth

forvalues b = 0/$bootstraps {
	di "B: `b'"
	
	preserve
	
	if `b' != 0 {
		bsample
	}


	foreach c in `categories' {
		
		// calculate factor
		qui gen `c'factor = .
	
		forvalues s = 0/1 {
			
			if "`c'" == "pinc" | "`c'" == "emp" {
				
				cap factor ${`c'latent} if male == `s' & abc == 1
				if !_rc {
					qui predict `c'factor_`s' 
					qui replace `c'factor = `c'factor_`s' if male == `s' & abc == 1
				}
				
				cap factor ${care`c'latent} if male == `s' & abc == 0
				if !_rc {
					qui predict care`c'factor_`s' 
					qui replace `c'factor = care`c'factor_`s' if male == `s' & abc == 0
				}
				
			}
			else {
				
				qui cap factor ${`c'latent} if male == `s' 
				if !_rc {
					qui predict `c'factor_`s' 
					qui replace `c'factor = `c'factor_`s' if male == `s' 
				}
			
			}
			
	
		}
	
		qui sum `c'factor
		qui replace `c'factor = (`c'factor - r(mean))/r(sd)
	
		forvalues s = 0/1 {
		
			// column 1: E(Y1 - Y0 | W=1), raw ITT
		
			qui sum `c'factor if R == 0 & male == `s'
			local `c'factor`s'0 = r(mean)
			
			qui sum `c'factor if R == 1 & male == `s'
			local `c'factor`s'1 = r(mean)
			
			local c1`c'`b' = ``c'factor`s'1' - ``c'factor`s'0'
			
			mat c1`s'`c' = (nullmat(c1`s'`c') \ `c1`c'`b'')
			mat colname c1`s'`c' = c1_`c'_`s'
			
			// column 3: E(Y1|R=1) - E(Y0 |  R=0,V=0), raw vs. stay at home
			qui reg `c'factor R if male == `s' & (R==1 | (R==0 & P==0))
			
			qui sum `c'factor if R == 0 & P == 0 & male == `s'
			local c3`c'factor`s'0 = r(mean)
			
			qui sum `c'factor if R == 1 & male == `s'
			local c3`c'factor`s'1 = r(mean)
			
			local c3`c'`b' = `c3`c'factor`s'1' - `c3`c'factor`s'0'
			
			mat c3`s'`c' = (nullmat(c3`s'`c') \ `c3`c'`b'')
			mat colname c3`s'`c' = c3_`c'_`s'
			
			// column 5: E(Y1|R=1) - E(Y0 |  R=0,V=1), raw vs. alternative
			qui sum `c'factor if R == 0 & P == 1 & male == `s'
			local c5`c'factor`s'0 = r(mean)
			
			qui sum `c'factor if R == 1 & male == `s'
			local c5`c'factor`s'1 = r(mean)
			
			local c5`c'`b' = `c5`c'factor`s'1' - `c5`c'factor`s'0'
			
			mat c5`s'`c' = (nullmat(c5`s'`c') \ `c5`c'`b'')
			mat colname c5`s'`c' = c5_`c'_`s'
		
		}
	}
		
	// generate imputed variables for factors used in columns 2, 4, 6
	foreach v in `toimpute' {
	
		local nimpute : word count ${`v'_impute}
	
		if `nimpute' > 0 {
			qui mi impute regress `v' = ${`v'_impute}, add(10) force
			qui rename `v' `v'old
			qui egen `v' = rowmean(_*_`v')
		}
	
	}
	
	// generate weights
	qui psmatch2 fakeR male hrabc_index apgar1 apgar5 abc if (P==0 & R==0) | R==1, ///
	kernel k(epan) bwidth(20) mahalanobis(male hrabc_index apgar1 apgar5 abc) 
	qui gen weightP0 = _weight
	
	qui psmatch2 fakeR male hrabc_index apgar1 apgar5 abc if (P==1 & R==0) | R==1, ///
	kernel k(epan) bwidth(20) mahalanobis(male hrabc_index apgar1 apgar5 abc) 
	qui gen weightP1 = _weight
		
	foreach c in `categories' {
		// calculate imputed factor
		qui gen `c'factorimp = .
	
		forvalues s = 0/1 {
			
			if "`c'" == "pinc" | "`c'" == "emp" {


				qui cap factor ${`c'latent} if male == `s' & abc == 1
				if !_rc {
					qui predict `c'factorimp_`s' 
					qui replace `c'factorimp  = `c'factorimp_`s' if male == `s' & abc == 1
				}
				
				qui cap factor ${care`c'latent} if male == `s' & abc == 0
				if !_rc {
					qui predict care`c'factorimp_`s' 
					qui replace `c'factorimp  = care`c'factorimp_`s' if male == `s' & abc == 0
				}
				
			}
			else {
				
				qui cap factor ${`c'latent} if male == `s' 
				if !_rc {
					qui predict `c'factorimp_`s' 
					qui replace `c'factorimp  = `c'factorimp_`s' if male == `s' 
				}
			
			}
			
	
		}
		
		qui sum `c'factorimp
		qui replace `c'factorimp = (`c'factorimp - r(mean))/r(sd)
		
		forvalues s = 0/1 {
			//column 2: E(Y1 - Y0 | B, W=1), conditional ITT
			qui reg `c'factorimp R hrabc_index apgar1 apgar5 if male == `s'
			mat c2`c'`s'b`b' = e(b)
			local c2`c'`b' = c2`c'`s'b`b'[1,1]
			mat c2`s'`c' = (nullmat(c2`s'`c') \ `c2`c'`b'')
			mat colnames c2`s'`c' = c2_`c'_`s'
			
			// column 4: E(Y1 - Y0 | B, V=0)
			qui reg `c'factorimp R hrabc_index apgar1 apgar5 abc ///
				if ((P==0 & R == 0) | R == 1) & male == `s' [pweight = weightP0]
			mat c4`c'`s'b`b' = e(b)
			local c4`c'`b' = c4`c'`s'b`b'[1,1]
			mat c4`s'`c' = (nullmat(c4`s'`c') \ `c4`c'`b'')
			mat colnames c4`s'`c' = c4_`c'_`s'
			
			// column 6: E(Y1 - Y0 | B, V=1)
			qui reg `c'factorimp R hrabc_index apgar1 apgar5 abc ///
				if ((P==1 & R == 0) | R == 1) & male == `s' [pweight = weightP1]
			mat c6`c'`s'b`b' = e(b)
			local c6`c'`b' = c6`c'`s'b`b'[1,1]
			mat c6`s'`c' = (nullmat(c6`s'`c') \ `c6`c'`b'')
			mat colnames c6`s'`c' = c6_`c'_`s'
		
		}
	}
	
	restore
}

// bring to data
foreach c in `categories' {
	forvalues s = 0/1 {
		forvalues i = 1/6 {
			
			mat COMBINE = (nullmat(COMBINE) , c`i'`s'`c')
		
		}
	
	}
}

clear
svmat COMBINE, names(col)


// inference
gen bs = _n - 1

foreach c in `categories' {
	forvalues s = 0/1 {
		forvalues i = 1/6 {
			
			sum c`i'_`c'_`s' if bs == 0
			gen c`i'_`c'_`s'_point = r(mean)
			global c`i'_`c'_`s'_point = r(mean)
			global c`i'_`c'_`s'_point : di %9.3f ${c`i'_`c'_`s'_point}
			
			sum c`i'_`c'_`s' if bs > 0
			gen c`i'_`c'_`s'_emp = r(mean)
			
			gen c`i'_`c'_`s'_dm = c`i'_`c'_`s' - c`i'_`c'_`s'_emp if bs > 0
			
			
			gen c`i'_`c'_`s'_count = (c`i'_`c'_`s'_dm >= c`i'_`c'_`s'_point) if bs > 0
			sum c`i'_`c'_`s'_count
			gen c`i'_`c'_`s'_p = r(mean)
			global c`i'_`c'_`s'_p = r(mean)
			global c`i'_`c'_`s'_p : di %9.3f ${c`i'_`c'_`s'_p }
			
			if ${c`i'_`c'_`s'_p } <= 0.1 {
				global c`i'_`c'_`s'_p \textbf{${c`i'_`c'_`s'_p}}
			}
			
		
		}
	
	}
}

// make table
file open tabfile using "${output}/latent-tes-1000.tex", replace write
file write tabfile "\begin{tabular}{l c c c c c c c}" _n
file write tabfile "\toprule" _n
file write tabfile " Category & Age & (1) & (2) & (3) & (4) & (5) & (6) \\" _n
file write tabfile "\midrule" _n

file write tabfile "\mc{8}{c}{\textit{\textbf{Females}}} \\" _n

foreach c in `categories' {
	file write tabfile "``c'_name' & ``c'_age' & ${c1_`c'_0_point} & ${c2_`c'_0_point} & ${c3_`c'_0_point} & ${c4_`c'_0_point} & ${c5_`c'_0_point} & ${c6_`c'_0_point} \\" _n
	file write tabfile "&  & (${c1_`c'_0_p}) & (${c2_`c'_0_p}) & (${c3_`c'_0_p}) & (${c4_`c'_0_p}) & (${c5_`c'_0_p}) & (${c6_`c'_0_p}) \\" _n
}

file write tabfile "\midrule" _n

file write tabfile "\mc{8}{c}{\textit{\textbf{Males}}} \\" _n

foreach c in `categories' {
	file write tabfile "``c'_name' & ``c'_age' & ${c1_`c'_1_point} & ${c2_`c'_1_point} & ${c3_`c'_1_point} & ${c4_`c'_1_point} & ${c5_`c'_1_point} & ${c6_`c'_1_point} \\" _n
	file write tabfile "&  & (${c1_`c'_1_p}) & (${c2_`c'_1_p}) & (${c3_`c'_1_p}) & (${c4_`c'_1_p}) & (${c5_`c'_1_p}) & (${c6_`c'_1_p}) \\" _n

}

file write tabfile "\bottomrule" _n
file write tabfile "\end{tabular}" _n
file write tabfile "% This file generated by: abccare-cba/scripts/abccare/genderdifferences/tes-latentoutcomes.do" _n
file close tabfile
