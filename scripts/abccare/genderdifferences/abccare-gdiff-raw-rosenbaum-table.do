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




local categories age5 age15 age34

// OUTPUT ORDER
local outgroups GTvC GTvGa GTvCh BTvC BTvCa BTvCh BCavCh GCavCh ChBvG CaBvG CBvG TBvG
// TABLE ORDER
local groupnames GTvC BTvC GTvCa BTvCa GTvCh BTvCh GCavCh BCavCh ChBvG CaBvG CBvG TBvG


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

forvalues i = 1/12 {
	
	local g : word `i' of `outgroups'
	
	foreach c in `categories' {
		
		qui sum `c' if n == `i'
		global pval`g' = r(mean)
	}
	
}

// calculate the rest of the statistics
// combine into a big matrix with the p-values as well
cd $data
use append-abccare_iv, clear

drop if R == 0 & RV == 1

// variables
cd ${scripts}/abccare/genderdifferences

	include abccare-reverse
	include abccare-112-outcomes
	include abccare-112-age-outcomes
	
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
global GCavCh_drop 	male == 1 & R == 1
global BCavCh_drop 	male == 0 & R == 1
global ChBvG_drop 	dc_alt > 0 & R == 1
global CaBvG_drop 	dc_alt == 0 & R == 1
global CBvG_drop 	R == 1
global TBvG_drop 	R == 0
	
// std. effect size (adapted from abccare-gdiff-stdtes-ranksum.do)
foreach g in `groupnames' {

	preserve
	
	drop if ${`g'_drop}
	
	foreach c in `categories' {
		
		global nvar`c' = 0
		global tot`g' = 0
		global npos`g' = 0
		global nsig`g' = 0

		foreach v in ``c'' {
			
			global nvar`c' = ${nvar`c'} + 1
		
			qui reg `v' ${`g'_v2} 
			mat B`v' = e(b)
			mat B`c' = (nullmat(B`c') \ B`v'[1,1])
		
			// record if B > 0
			if B`v'[1,1] > 0 {
				global npos`g' = ${npos`g'} + 1
					
				// record if B > 0 & significant
				ttest `v', by(${`g'_v2})
				if r(p) <= 0.1 {
					global nsig`g' = ${nsig`g'} + 1
				}	
			}
		
			qui sum `v' if ${`g'_v2} == 0
			local `v'sd = r(sd)
			
			if ``v'sd' == 0 {
				di "No variation, `c', `v'"
				mat STDB`c' = (nullmat(STDB`c') \ .)
			}
			else if ``v'sd' == . {
				di "Missing sd, `c', `v'"
				mat STDB`c' = (nullmat(STDB`c') \ .)
			}
			else {
				local `v'stdb = B`v'[1,1]/``v'sd'
				//mat STDB`c' = (nullmat(STDB`c') \ ``v'stdb')
				//mat colnames STDB`c' = `g'
				global tot`g' = ${tot`g'} + ``v'stdb'
			}
		}
		
		global pos`g' = ${npos`g'}/${nvar`c'}
		global sig`g' = ${nsig`g'}/${nvar`c'}
		global avg`c'_`g' = ${tot`g'}/${nvar`c'}
		
		mat COMBINE`g' = (nullmat(COMBINE`g') \ ${avg`c'_`g'} \ ${pos`g'} \ ${sig`g'})
		mat colnames COMBINE`g' = `g'
	}
	
	mat COMBINE = (nullmat(COMBINE) , COMBINE`g')

	restore
}

	
