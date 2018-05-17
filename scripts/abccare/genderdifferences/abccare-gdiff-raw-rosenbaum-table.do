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
global bootstraps 2
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



cd ${scripts}/abccare/genderdifferences

	include abccare-112-outcomes
	
local categories age5 age15 age34 iq ach se mlabor parent edu emp crime risk health all


local age5_name	"Childhood"
local age15_name "School Age"
local age34_name "Adulthood"
local iq_name "IQ"
local ach_name "Achievement"
local se_name "Social-emotional"
local mlabor_name "Mother's Labor"
local parent_name "Parenting"
local edu_name "Education"
local emp_name "Employment"
local crime_name "Crime"
local risk_name "Risky Behaviors"
local health_name "Health"
local all_name "All"

// OUTPUT ORDER
local outgroups GTvC GTvCa GTvCh BTvC BTvCa BTvCh BCavCh GCavCh ChBvG CaBvG CBvG TBvG
// TABLE ORDER
local exp_groupnames 		GTvC //BTvC //GTvCa BTvCa GTvCh BTvCh //GCavCh BCavCh 
local gender_groupnames 	ChBvG CaBvG CBvG TBvG
local cats					exp //gender

// import and organize Rosenbaum p-values
cd $output


// A
import delim using "rosenbaum-output-Afactors.txt", delim(",") clear
gen n = _n
order n, first
keep if n == 5 | n == 6 | n == 11 | n == 12 | n == 17 | n == 18 | n == 23 ///
				| n == 24 | n == 29 | n == 30 | n == 35 | n == 36
gen n2 = _n
order n2, first
keep if mod(n2,2) == 0
drop n n2
gen n = _n
order n, first
tempfile A
save	`A'

// B
import delim using "rosenbaum-output-Bfactors.txt", delim(",") clear
gen n = _n
order n, first
keep if n == 5 | n == 6 | n == 11 | n == 12
gen n2 = _n
order n2, first
keep if mod(n2,2) == 0
drop n n2
gen n = _n + 6
order n, first
tempfile B
save	`B'

// C
import delim using "rosenbaum-output-Cfactors.txt", delim(",") clear
gen n = _n
order n, first
keep if n == 5 | n == 6 | n == 11 | n == 12 | n == 17 | n == 18 | n == 23 | n == 24 
gen n2 = _n
order n2, first
keep if mod(n2,2) == 0
drop n n2
gen n = _n + 8
order n, first
tempfile C
save	`C'

append using `A'
append using `B'
sort n

rename fiq		iq
rename fach		ach
rename fse		se
rename fmlabor	mlabor
rename fparent	parent
rename fedu		edu
rename femp		emp
rename fcrime	crime
rename frisk	risk
rename fhealth	health
rename fall		all

forvalues i = 1/12 {
	
	local g : word `i' of `outgroups'
	
	foreach c in `categories' {
		di "g:`g', c:`c'"
		qui sum `c' if n == `i'
		global pval`g'`c' = r(mean)
		global pval`g'`c' : di %9.3f ${pval`g'`c'}
	}
	
}

// calculate the rest of the statistics
// combine into a big matrix with the p-values as well
cd $data
use append-abccare_iv, clear

drop if R == 0 & RV == 1
factor  m_age_base m_ed_base m_iq_base hh_sibs_base m_married_base f_home0y
predict factorbase 
sum factorbase, detail
gen base = (factorbase <= r(p50))
keep if base == 0

// variables
cd ${scripts}/abccare/genderdifferences

	include abccare-reverse
	include abccare-112-outcomes

local age_categories 	age5 //age15 age34 all
local cats_categories 	iq //ach se mlabor parent edu emp crime risk health 

local agecats_types		cats age

gen alt = (dc_alt > 0 & R == 0)
replace alt = . if dc_alt == . | R == 1

global GTvC_v2 		R
global BTvC_v2 		R
global GTvCa_v2 	R
global BTvCa_v2 	R
global GTvCh_v2 	R
global BTvCh_v2 	R
global GCavCh_v2 	alt
global BCavCh_v2 	alt
global ChBvG_v2 	male
global CaBvG_v2 	male
global CBvG_v2 		male
global TBvG_v2 		male

global GTvC_drop 	male == 1	
global BTvC_drop 	male == 0
global GTvCa_drop 	male == 1 & dc_alt == 0 
global BTvCa_drop 	male == 0 & dc_alt == 0
global GTvCh_drop 	male == 1 & dc_alt > 0
global BTvCh_drop 	male == 0 & dc_alt > 0
global GCavCh_drop 	male == 1 | R == 1
global BCavCh_drop 	male == 0 | R == 1
global ChBvG_drop 	dc_alt > 0 | R == 1
global CaBvG_drop 	dc_alt == 0 | R == 1
global CBvG_drop 	R == 1
global TBvG_drop 	R == 0
	
// std. effect size (adapted from abccare-gdiff-stdtes-ranksum.do)


local colnames
foreach t in `cats' {
	foreach t2 in `agecats_types' {

		foreach g in ``t'_groupnames' {
				
			forvalues b = 0/${bootstraps} {
			
				di "bootstrap: `b', `g', `t', `t2'"
			
				
			
				preserve
				drop if ${`g'_drop}
			
				if `b' != 0 {
					bsample
				}

				foreach c in ``t2'_categories' {
					
					if `b' == 0 {
						local colnames `colnames' `g'std`c' `g'pos`c' `g'sig`c' `g'p`c'
					}
					
					global nvar`c'_`b' = 0
					global tot`g'_`b' = 0
					global npos`g'_`b' = 0
					global nsig`g'_`b' = 0
					global nsiga`g'_`b' = 0
					
					foreach v in ``c'_updated' {
					
						
			
						global nvar`c'_`b' = ${nvar`c'_`b'} + 1
		
						qui reg `v' ${`g'_v2} 
						mat B`v'_`b' = e(b)
						mat B`c'_`b' = (nullmat(B`c'_`b') \ B`v'_`b'[1,1])
						global B`v'_`b' = B`v'_`b'[1,1]
						
						// record if B > 0
						if B`v'_`b'[1,1] > 0 {
							global npos`g'_`b' = ${npos`g'_`b'} + 1
					
							// record if B > 0 & significant asymptotically
							qui ttest `v', by(${`g'_v2})
							if r(p) <= 0.1 {
								global nsiga`g'_`b' = ${nsiga`g'_`b'} + 1
							}	
						}	
						
						// determine significance of B
						global B`v'_`b'_tot = 0
						global B`v'_`b'_count = 0
						
						forvalues b1 = 1/${bootstraps} {
							di "bootstrap inner: `b1'"
							tempfile preserve`b'
							qui save `preserve`b''
							
							bsample
							
							qui reg `v' ${`g'_v2} 
							mat B`v'_`b' = e(b)
							global B`v'_`b'_`b1' = B`v'_`b'[1,1]
							di "B `b1' ${B`v'_`b'_`b1'}"
							
							global B`v'_`b'_tot = ${B`v'_`b'_tot} + ${B`v'_`b'_`b1'}
							di "B total `b1' ${B`v'_`b'_tot}"
							
							use `preserve`b'', clear
						
						}
						
						global B`v'_`b'_avg = ${B`v'_`b'_tot}/${bootstraps}
						di "B average ${B`v'_`b'_avg}"
						
						forvalues b1 = 1/${bootstraps} {
							global B`v'_`b'_`b1'_dm = ${B`v'_`b'_`b1'} - ${B`v'_`b'_avg}
							if ${B`v'_`b'_`b1'_dm } >= ${B`v'_`b'} {
								
								global B`v'_`b'_count = ${B`v'_`b'_count} + 1
								di "B count `b' ${B`v'_`b'_count}"
							}
						
						}
						
						global `v'_`b'_bspval = ${B`v'_`b'_count}/${bootstraps}
						di "PVALUE `b' ${`v'_`b'_bspval}"
						if ${`v'_`b'_bspval} <= 0.1 {
							global nsig`g'_`b' = ${nsig`g'_`b'} + 1
						}	
		
						// calculate effect size
						qui sum `v' if ${`g'_v2} == 0
						local `v'sd = r(sd)
			
						if ``v'sd' == 0 {
							di "No variation, `c', `v'"
							mat STDB`c'_`b' = (nullmat(STDB`c'_`b') \ .)
							global nvar`c'_`b' = ${nvar`c'_`b'} - 1
						}
						else if ``v'sd' == . {
							di "Missing sd, `c', `v'"
							mat STDB`c'_`b' = (nullmat(STDB`c'_`b') \ .)
							global nvar`c'_`b' = ${nvar`c'_`b'} - 1
						}
						else {
							local `v'stdb_`b' = B`v'_`b'[1,1]/``v'sd'
							global tot`g'_`b' = ${tot`g'_`b'} + ``v'stdb_`b''
						}
					}
		
					global pos`g'_`b' = (${npos`g'_`b'}/${nvar`c'_`b'}) * 100
					global sig`g'_`b' = (${nsig`g'_`b'}/${nvar`c'_`b'}) * 100
					global avg`c'_`g'_`b' = ${tot`g'_`b'}/${nvar`c'_`b'}
		
					global pos`g'_`b' : di ${pos`g'_`b'} %9.0f
					global sig`g'_`b' : di ${sig`g'_`b'} %9.0f
					global avg`c'_`g'_`b' : di ${avg`c'_`g'_`b'} %9.3f
					global pval`g'`c' : di ${pval`g'`c'} %9.3f
		
					mat COMBINE`b' = (nullmat(COMBINE`b') , ${avg`c'_`g'_`b'} , ${pos`g'_`b'} , ${sig`g'_`b'} , ${pval`g'`c'})
					
				}

				
			//mat colnames COMBINE`t2'`b' = ``t'`t2'colnames'
			
			
			restore
				
		}
	
		}
		
		
	}
}

// test significance
forvalues b = 0/$bootstraps {
	mat COMBINE = (nullmat(COMBINE) \ COMBINE`b')

}
mat colnames COMBINE = `colnames'

clear
svmat COMBINE, names(col)
gen b = _n - 1
	
foreach t in `cats' {
	foreach t2 in `agecats_types' {
		foreach g in ``t'_groupnames' {
			foreach c in ``t2'_categories' {
				
				foreach s in std pos sig {
				
					sum `g'`s'`c' if b == 0
					gen point`g'`s'`c' = r(mean) 
					global point`g'`s'`c' = r(mean)
					global point`g'`s'`c' : di %9.3f ${point`g'`s'`c'}
					
					sum `g'`s'`c' if b > 0
					gen mean`g'`s'`c' = r(mean)
					
					gen dmean`g'`s'`c' = `g'`s'`c' - mean`g'`s'`c' if b > 0
					gen com`g'`s'`c' = (dmean`g'`s'`c' >= mean`g'`s'`c') if b > 0
					sum com`g'`s'`c' if b > 0
					
					gen p`g'`s'`c' = r(mean)
					global p`g'`s'`c' = r(mean)
					
					if ${p`g'`s'`c'} <= 0.1 {
						global point`g'`s'`c' \textbf{${point`g'`s'`c'}}
					}
				
				}
					
			}
		}
	}
}
	

// make table
foreach t in `cats' {
	foreach t2 in `agecats_types' {
		foreach g1 in TvC TvCa TvCh {
		
		file open tabfile using "${output}/raw-rosenbaum-table-`t2'-`t'-`g1'.tex", replace write
		file write tabfile "\begin{tabular}{l c c c c}" _n
		file write tabfile "\toprule" _n
		file write tabfile " & Average & \% $ >0 $ & \% $ >0 $ , Significant & \citet{Rosenbaum_2005_Distribution_JRSS} \\" _n
		file write tabfile " & Effect Size & Treatment Effect & Treatment Effect & $ p $ -value \\" _n
		file write tabfile "\midrule" _n
		
			foreach c in ``t2'_categories' {
			
				file write tabfile "\textbf{``c'_name'} & & & & \\" _n
				file write tabfile "\quad Females &  ${pointG`g1'std`c'} & ${pointG`g1'pos`c'} & ${pointG`g1'sig`c'} & ${pvalG`g1'`c'} \\" _n
				file write tabfile "\quad Males &  ${pointB`g1'std`c'} & ${pointB`g1'pos`c'} & ${pointB`g1'sig`c'} & ${pvalB`g1'`c'} \\" _n
				file write tabfile "\midrule" _n
			}
			
		file write tabfile "\bottomrule" _n
		file write tabfile "\end{tabular}" _n
		file write tabfile "% This file generated by: ${mediation}/scripts/abccare/genderdifferences/abccare-gdiff-raw-rosenbaum-table.do" _n
		file close tabfile	
		
		}
	}
}


