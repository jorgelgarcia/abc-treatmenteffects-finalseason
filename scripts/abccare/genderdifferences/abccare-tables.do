/* 
Project:				Skills Documentation of ABC/CARE
Author:					Ruby Zhang (rzhang15@uchicago.edu)
Original Date:			April 25, 2017

This file:				Table of variables with cognitive, non-cognitive, parenting, home 

Output: 				Table with variables of four categories
*/

clear all
set more off

// parameters
set seed 1
global bootstraps 10
global quantiles 30

// macros
global projects		: env projects
global klmshare		: env klmshare
global klmmexico	: env klmMexico

// filepaths
global abccare_output 		= "${klmmexico}/klmPFL/abccare"
global scripts    			= "$projects/abccare-cba/scripts/"
global output      			= "$projects/abccare-cba/output/"

// data
cd $abccare_output
use abccare-mediation-extended.dta, clear

// variables
# delimit ;
global iq				iq2y iq3y iq3y6m iq4y iq4y6m iq5y iq7y iq8y iq12y iq15y
						vrb2y vrb3y vrb3y6m vrb4y vrb4y6m vrb5y vrb8y vrb12y vrb15y
						prf2y prf3y prf3y6m prf4y prf4y6m prf5y prf8y prf12y prf15y
						wis_vrb12y wis_prf12y;

global socioemo			ibr_task0y6m ibr_task1y ibr_task1y6m ibr_task2y ibr_actv0y6m ibr_actv1y ibr_actv1y6m ibr_actv2y ibr_sociab0y6m ibr_sociab1y ibr_sociab1y6m ibr_sociab2y
						new_kr_dst2y kr_att2y new_kr_withd2y kr_conf2y
						new_cbi_iv5y6m new_cbi_di5y6m new_cbi_de5y6m 
						cbi_ex5y6m cbi_cr5y6m cbi_ve5y6m cbi_ta5y6m cbi_co5y6m
						new_wlkr_act8y new_wlkr_withd8y new_wlkr_dst8y new_wlkr_peer8y new_wlkr_immt8y
						new_cbi_ho12y new_cbi_de12y new_cbi_di12y new_cbi_iv12y 
						cbi_ex12y cbi_cr12y cbi_ve12y cbi_ta12y cbi_co12y
						new_kr_dst7y kr_att7y new_kr_withd7y kr_conf7y
						new_easy_gen new_easy_fear new_easy_ang new_easy_temp new_easy_vig new_easy_cont new_easy_deci new_easy_sens new_easy_pers easy_soci;
						
global ach				read5y6m math5y6m know5y6m
						read6y math6y know6y
						read7y6m math7y6m know7y6m 
						read8y math8y know8y 
						read8y6m math8y6m know8y6m 
						read9y math9y know9y
						read12y math12y know12y
						read21y math21y 
						cat_readst8y cat_mathst8y
						wj_read7y6m wj_math7y6m 
						wj_read8y wj_math8y wj_read8y6m wj_math8y6m 
						wj_read9y wj_math9y wj_read12y wj_math12y;

global parenting		home0y6m home1y6m home2y6m
						home3y6m home4y6m home8y
						home_abspun2y6m home_abspun1y6m home_abspun0y6m home_abspun4y6m home_abspun3y6m
						home_minvol0y6m home_minvol1y6m home_minvol2y6m 
						home_affect4y6m home_affect3y6m home_affect2y6m home_affect1y6m home_affect0y6m
						home_orgenv2y6m home_orgenv1y6m home_orgenv0y6m 
						home_oppvar2y6m home_oppvar1y6m home_oppvar0y6m
						home_toys2y6m home_toys1y6m home_toys0y6m
						home_abspun4y6m home_abspun3y6m home_abspun2y6m home_abspun1y6m home_abspun0y6m
						home_oppvar8y home_devstm8y home_emotin8y home_indep8y 
						home_leng8y home_absrst8y home_orgenv8y home_phyenv8y home_toys8y
						new_pari_auth0y6m new_pari_hostl0y6m new_pari_demo0y6m
						new_pari_auth1y6m new_pari_hostl1y6m new_pari_demo1y6m;

global categories		iq socioemo ach parenting;
# delimit cr

// Constructing the table

foreach c in $categories {

	file open tabfile using "${output}/abccare-var-`c'.tex", replace write
	file write tabfile "\begin{longtable}{c c c c c c}" _n
	file write tabfile "\toprule" _n
	file write tabfile "\textbf{Variable} & \textbf{Male} & \textbf{Male S.E.}  & \textbf{Female} & \textbf{Female S.E.} & \textbf{P-value} \\" _n
	file write tabfile "\midrule" _n
	
	foreach var_list in ${`c'} {

		cd $abccare_output
		use abccare-mediation-extended.dta, clear
			
		local varlabel: var label `var_list'

		//Bootstrapping for mean
		forvalues b = 0/$bootstraps {

			preserve
			
				if `b' > 0 {
					bsample			// this resamples with replacement
				}					// don't do this at `b'==0 to get point estimate 
									// (with original sample)
					
				sum `var_list' if male==0
				local mean_f = r(mean)
				sum `var_list' if male==1
				local mean_m = r(mean)
				matrix mean`b' = `mean_f' - `mean_m'
				
				// two matrices
				matrix allmeans = (nullmat(allmeans) \ mean`b')
			
			restore
		}

		preserve 
			clear
			svmat allmeans
	
			// hypothesis testing
			gen n = _n
			sum allmeans1 if n == 1
			gen point = r(mean)
	
			sum allmeans1 if n > 1
			gen empirical_mean = r(mean)
		
			// test if mean for control group same as treatment group
			gen demean = allmeans1 - empirical_mean if n > 1
			gen diffxgen = (abs(demean) > abs(point)) if n > 1
			sum diffxgen
			local p_sex = string(r(mean), "%9.3f") 
		restore
		
		preserve
			collapse (mean) mean`var_list' = `var_list' (sem) se`var_list' =`var_list', by(male)
			
			local mean`var_list'0 = string(mean`var_list'[1], "%9.3f")
			local mean`var_list'1 = string(mean`var_list'[2], "%9.3f")
			
			local se`var_list'0 = string(se`var_list'[1], "%9.3f")
			local se`var_list'1 = string(se`var_list'[2], "%9.3f")
		restore
		
		if `p_sex' <= 0.1 {
			file write tabfile "\texttt{\detokenize{`var_list'}} & \textbf{`mean`var_list'1'} & `se`var_list'1' &  \textbf{`mean`var_list'0'} & `se`var_list'0' & `p_sex' \\" _n
		}
		else {
			file write tabfile "\texttt{\detokenize{`var_list'}} & `mean`var_list'1' & `se`var_list'1' &  `mean`var_list'0' & `se`var_list'0' & `p_sex' \\" _n
		}
		mat drop allmeans

	}
		
	file write tabfile "\bottomrule" _n
	file write tabfile "\end{longtable}" _n
	file write tabfile "% This file generated by: ${abccare-cba}/scripts/abccare/genderdifferences/abccare-tables.do" _n
	file close tabfile
}
