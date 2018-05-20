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
global bootstraps 10
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

cd ${scripts}/abccare/genderdifferences

	include abccare-reverse
	//include abccare-112-outcomes
	
	
local categories pinc edu emp crime hyp
	
global pinclatent 		p_inc1y6m p_inc2y6m p_inc3y6m p_inc4y6m p_inc8y p_inc12y p_inc15y p_inc21y
global edulatent 		sch_hs30y si30y_techcc_att si30y_univ_comp years_30y ever_sped tot_sped ever_ret tot_ret
global emplatent 		si30y_works_job si21y_inc_labor si30y_inc_labor si21y_inc_trans_pub si30y_inc_trans_pub
global crimelatent 		ad34_fel ad34_mis si30y_adlt_totinc
global hyplatent 		si34y_sys_bp si34y_dia_bp si34y_prehyper si34y_hyper

global carepinclatent 		p_inc1y6m p_inc2y6m p_inc3y6m p_inc4y6m
global careedulatent 		sch_hs30y si30y_techcc_att si30y_univ_comp years_30y ever_sped tot_sped ever_ret tot_ret


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
				
				qui factor ${abc`c'latent} if male == `s' & abc == 1
				qui predict abc`c'factor_`s' 
				qui replace `c'factor = abc`c'factor_`s' if male == `s' & abc == 1
			
				qui factor ${care`c'latent} if male == `s' & abc == 0
				qui predict care`c'factor_`s' 
				qui replace `c'factor = care`c'factor_`s' if male == `s' & abc == 0
				
			}
			else {
				
				qui factor ${`c'latent} if male == `s' 
				qui predict `c'factor_`s' 
				qui replace `c'factor = `c'factor_`s' if male == `s' 
			
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
			mat colname c1`s'`c' = c1`s'`c'
			
			// column 2: E(Y1 - Y0 | B, W=1), conditional ITT
			qui cap teffects ipw (`c'factor) (R abc hrabc_index apgar1 apgar5) if male == `s'
			if !_rc {
				mat c2`c'`s'b`b' = e(b)
				local c2`c'`b' = c2`c'`s'b`b'[1,1]
			
				mat c2`s'`c' = (nullmat(c2`s'`c') \ `c2`c'`b'')
			}
			else {
				mat c2`s'`c' = (nullmat(c2`s'`c') \ .)
			}
			
			// column 3: E(Y1|R=1) - E(Y0 |  R=0,V=0), raw vs. stay at home
			qui reg `c'factor R if male == `s' & (R==1 | (R==0 & P==0))
			
			qui sum `c'factor if R == 0 & P == 0 & male == `s'
			local c3`c'factor`s'0 = r(mean)
			
			qui sum `c'factor if R == 1 & male == `s'
			local c3`c'factor`s'1 = r(mean)
			
			local c3`c'`b' = `c3`c'factor`s'1' - `c3`c'factor`s'0'
			
			mat c3`s'`c' = (nullmat(c3`s'`c') \ `c3`c'`b'')
			mat colname c3`s'`c' = c3`s'`c'
			
			// column 4: E(Y1 - Y0 | B, V=0)
			qui psmatch2 R male hrabc_index apgar1 apgar5 abc if (P==0 & R == 0) | R == 1, ///
			kernel k(epan) bwidth(20) mahalanobis(male hrabc_index apgar1 apgar5 abc) 
			
			qui cap teffects ipw (`c'factor) (_treated abc hrabc_index apgar1 apgar5) if male == `s'
			if !_rc {
				mat c4`c'`s'b`b' = e(b)
				local c4`c'`b' = c4`c'`s'b`b'[1,1]
			
				mat c4`s'`c' = (nullmat(c4`s'`c') \ `c4`c'`b'')
			}
			else {
				mat c4`s'`c' = (nullmat(c4`s'`c') \ .)
			}
			
			
			// column 5: E(Y1|R=1) - E(Y0 |  R=0,V=1), raw vs. alternative
			qui sum `c'factor if R == 0 & P == 1 & male == `s'
			local c5`c'factor`s'0 = r(mean)
			
			qui sum `c'factor if R == 1 & male == `s'
			local c5`c'factor`s'1 = r(mean)
			
			local c5`c'`b' = `c5`c'factor`s'1' - `c5`c'factor`s'0'
			
			mat c5`s'`c' = (nullmat(c5`s'`c') \ `c5`c'`b'')
			mat colname c5`s'`c' = c5`s'`c'
		
		
			// column 6: E(Y1 - Y0 | B, V=1)
			qui psmatch2 R male hrabc_index apgar1 apgar5 abc if (P==1 & R == 0) | R == 1, ///
			kernel k(epan) bwidth(20) mahalanobis(male hrabc_index apgar1 apgar5 abc)
			
			qui cap teffects ipw (`c'factor) (_treated abc hrabc_index apgar1 apgar5) if male == `s'
			if !_rc {
				mat c6`c'`s'b`b' = e(b)
				local c6`c'`b' = c6`c'`s'b`b'[1,1]
			
				mat c6`s'`c' = (nullmat(c6`s'`c') \ `c6`c'`b'')
			}
			else {
				mat c6`s'`c' = (nullmat(c6`s'`c') \ .)
			}
			
		
		
		}
		
		
		
	}
	
	restore
}
