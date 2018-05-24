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
global dbootstraps 1
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
local exp_groupnames 		GTvC BTvC GTvCa BTvCa GTvCh BTvCh //GCavCh BCavCh 
local gender_groupnames 	ChBvG CaBvG CBvG TBvG
local cats					exp //gender

// import and organize Rosenbaum p-values
cd $output


// A
import delim using "rosenbaum-output-Afactors.txt", delim(",") clear
qui gen n = _n
keep if n == 5 | n == 6 | n == 11 | n == 12 | n == 17 | n == 18 | n == 23 ///
				| n == 24 | n == 29 | n == 30 | n == 35 | n == 36
qui gen n2 = _n
keep if mod(n2,2) == 0
drop n n2
qui gen n = _n
tempfile A
qui save	`A'

// B
import delim using "rosenbaum-output-Bfactors.txt", delim(",") clear
qui gen n = _n
keep if n == 5 | n == 6 | n == 11 | n == 12
qui gen n2 = _n
qui keep if mod(n2,2) == 0
drop n n2
qui gen n = _n + 6
tempfile B
qui save	`B'

// C
import delim using "rosenbaum-output-Cfactors.txt", delim(",") clear
qui gen n = _n
keep if n == 5 | n == 6 | n == 11 | n == 12 | n == 17 | n == 18 | n == 23 | n == 24 
qui gen n2 = _n
keep if mod(n2,2) == 0
drop n n2
qui gen n = _n + 8
tempfile C
qui save	`C'

append using `A'
append using `B'

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

/*
factor  m_age_base m_ed_base m_iq_base hh_sibs_base m_married_base f_home0y
predict factorbase 
qui sum factorbase, detail
qui gen base = (factorbase <= r(p50))
keep if base == 0
*/

// variables
cd ${scripts}/abccare/genderdifferences

	include abccare-reverse
	include abccare-112-outcomes

local age_categories 	age5 age15 age34 all
local cats_categories 	iq ach se mlabor parent edu emp crime risk health 

keep id R RV P male `iq_big' `ach_big' `se_big' `mlabor_big' `parent_big' `edu_big' ///
	`emp_big' `crime_big' `risk_big' `health_big' `age5_big' `age15_big' `age34_big' `all_big'

local agecats_types		cats age

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
global GTvCa_drop 	male == 1 & P == 0 
global BTvCa_drop 	male == 0 & P == 0
global GTvCh_drop 	male == 1 & P == 1
global BTvCh_drop 	male == 0 & P == 1
global GCavCh_drop 	male == 1 | R == 1
global BCavCh_drop 	male == 0 | R == 1
global ChBvG_drop 	P == 1 | R == 1
global CaBvG_drop 	P == 0 | R == 1
global CBvG_drop 	R == 1
global TBvG_drop 	R == 0
	
// std. effect size (adapted from abccare-gdiff-stdtes-ranksum.do)


local colnames
foreach t in `cats' {
	foreach t2 in `agecats_types' {

		foreach g in ``t'_groupnames' {
				
			forvalues b = 0/${bootstraps} {
				di "`t' `t2' `g'"
				di "Bootstrap: `b'"
				
				
				global nvarall_`b' = 0
				global totall`g'_`b' = 0
				global nposall`g'_`b' = 0
				global nsigall`g'_`b' = 0
				global nsigaall`g'_`b' = 0
			
				preserve
				qui drop if ${`g'_drop}
			
				if `b' != 0 {
					bsample
				}

				foreach c in ``t2'_categories' {
				
				if `b' == 0 {
					local colnames `colnames' `g'std`c' `g'pos`c' `g'sig`c' `g'p`c'
				}
				
				if "`c'" != "all" {
					di "`c'"
					
					
					global nvar`c'_`b' = 0
					global tot`g'_`b' = 0
					global npos`g'_`b' = 0
					global nsig`g'_`b' = 0
					global nsiga`g'_`b' = 0
					
					foreach v in ``c'_big' {
			
						global nvar`c'_`b' = ${nvar`c'_`b'} + 1
						global nvarall_`b' = ${nvarall_`b'} + 1
						
						qui reg `v' ${`g'_v2} 
						
						mat B`v'_`b' = e(b)
						global B`v'_`b' = B`v'_`b'[1,1]
						
						// record if B > 0
						if B`v'_`b'[1,1] > 0 {
							global npos`g'_`b' = ${npos`g'_`b'} + 1
							global nposall`g'_`b' = ${nposall`g'_`b'} + 1
						}	
						
						// determine significance of B
						global B`v'_`b'_tot = 0
						global B`v'_`b'_count = 0
						
						global denom = ${dbootstraps}
						forvalues b1 = 1/${dbootstraps} {
						
							tempfile preserve`b'
							qui save `preserve`b''
							
							bsample
							
							cap qui reg `v' ${`g'_v2} 
							if !_rc {
								mat B`v'_`b'_`b1' = e(b)
								global B`v'_`b'_`b1' = B`v'_`b'_`b1'[1,1]
							
								global B`v'_`b'_tot = ${B`v'_`b'_tot} + ${B`v'_`b'_`b1'}
							}
							else {
								global denom = ${denom} - 1
							}

							use `preserve`b'', clear
							erase `preserve`b''
						
						}
						
						global B`v'_`b'_avg = ${B`v'_`b'_tot}/${denom}
						
						forvalues b1 = 1/${denom} {
							global B`v'_`b'_`b1'_dm = ${B`v'_`b'_`b1'} - ${B`v'_`b'_avg}
							if ${B`v'_`b'_`b1'_dm } >= ${B`v'_`b'} {
								
								global B`v'_`b'_count = ${B`v'_`b'_count} + 1
							}
						
						}
						
						global `v'_`b'_bspval = ${B`v'_`b'_count}/${denom}
						if ${`v'_`b'_bspval} <= 0.1 {
							global nsig`g'_`b' = ${nsig`g'_`b'} + 1
							global nsigall`g'_`b' = ${nsigall`g'_`b'} + 1
						}	
		
						// calculate effect size
						qui sum `v' if ${`g'_v2} == 0
						local `v'sd = r(sd)
			
						if ``v'sd' == 0 {
							mat STDB`c'_`b' = (nullmat(STDB`c'_`b') \ .)
							global nvar`c'_`b' = ${nvar`c'_`b'} - 1
							global nvarall_`b' = ${nvarall_`b'} - 1
						}
						else if ``v'sd' == . {
							mat STDB`c'_`b' = (nullmat(STDB`c'_`b') \ .)
							global nvar`c'_`b' = ${nvar`c'_`b'} - 1
							global nvarall_`b' = ${nvarall_`b'} - 1
						}
						else {
							local `v'stdb_`b' = B`v'_`b'[1,1]/``v'sd'
							global tot`g'_`b' = ${tot`g'_`b'} + ``v'stdb_`b''
							global totall`g'_`b' = ${totall`g'_`b'} + ``v'stdb_`b''
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
				if "`c'" == "all" {
					di "`c'"
					global posall`g'_`b' = (${nposall`g'_`b'}/${nvarall_`b'}) * 100
					global sigall`g'_`b' = (${nsigall`g'_`b'}/${nvarall_`b'}) * 100
					global avgall_`g'_`b' = ${totall`g'_`b'}/${nvarall_`b'}

		
					global posall`g'_`b' : di ${posall`g'_`b'} %9.0f
					global sigall`g'_`b' : di ${sigall`g'_`b'} %9.0f
					global avgall_`g'_`b' : di ${avgall_`g'_`b'} %9.3f
					global pval`g'all : di ${pval`g'all} %9.3f
		
					mat COMBINE`b' = (nullmat(COMBINE`b') , ${avgall_`g'_`b'} , ${posall`g'_`b'} , ${sigall`g'_`b'} , ${pval`g'all})

				}
				}
			
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
qui gen b = _n - 1

global std_comp = 0
global pos_comp = 50
global sig_comp = 10
	
foreach t in `cats' {
	foreach t2 in `agecats_types' {
		foreach g in ``t'_groupnames' {
			foreach c in ``t2'_categories' {
				
				foreach s in std pos sig {
				
					qui sum `g'`s'`c' if b == 0
					qui gen point`g'`s'`c' = r(mean) 
					global point`g'`s'`c' = r(mean)
					global point`g'`s'`c' : di %9.3f ${point`g'`s'`c'}
					
					qui sum `g'`s'`c' if b > 0
					qui gen mean`g'`s'`c' = r(mean)
					
					qui gen dmean`g'`s'`c' = `g'`s'`c' - mean`g'`s'`c' if b > 0
					qui gen com`g'`s'`c' = (dmean`g'`s'`c' >= point`g'`s'`c' + ${`s'_comp}) if b > 0
					qui sum com`g'`s'`c' if b > 0
					
					qui gen p`g'`s'`c' = r(mean)
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
		
		file open tabfile using "${output}/raw-rosenbaum-table-`t2'-`t'-`g1'-big-${bootstraps}-${dbootstraps}.tex", replace write
		file write tabfile "\begin{tabular}{l c c c c}" _n
		file write tabfile "\toprule" _n
		file write tabfile " & Average & \% $ >0 $ & \% $ >0 $ , Significant & \citet{Rosenbaum_2005_Distribution_JRSS} \\" _n
		file write tabfile " & Effect Size & Treatment Effect & Treatment Effect & $ p $ -value \\" _n

		
			foreach c in ``t2'_categories' {
			
				file write tabfile "\midrule" _n
				file write tabfile "\textbf{``c'_name'} & & & & \\" _n
				file write tabfile "\quad Females &  ${pointG`g1'std`c'} & ${pointG`g1'pos`c'} & ${pointG`g1'sig`c'} & ${pvalG`g1'`c'} \\" _n
				file write tabfile "\quad Males &  ${pointB`g1'std`c'} & ${pointB`g1'pos`c'} & ${pointB`g1'sig`c'} & ${pvalB`g1'`c'} \\" _n
				
			}
			
		file write tabfile "\bottomrule" _n
		file write tabfile "\end{tabular}" _n
		file write tabfile "% This file generated by: ${mediation}/scripts/abccare/genderdifferences/abccare-gdiff-raw-rosenbaum-table-big.do" _n
		file close tabfile	
		
		}
	}
}


