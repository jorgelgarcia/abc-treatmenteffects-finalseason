gen new_id = _n

tempfile prefactor
save `prefactor', replace


local factor_iq5 iq2y iq3y iq3y6m iq4y iq4y6m iq5y /*iq2y6m*/
local factor_iq12 iq7y iq8y iq12y /*iq6y */
local factor_iq21 iq15y iq21y  

local factor_achv12 ach5y6m ach6y ach6y6m ach7y ach7y6m ach8y ach8y6m piat_math7y /*ach12y*/
local factor_achv21 ach15y ach21y 
 
local factor_home home0y6m home1y6m home2y6m home3y6m home4y6m home8y 

local factor_pinc p_inc1y6m p_inc2y6m p_inc3y6m p_inc4y6m p_inc8y p_inc12y p_inc15y

local factor_mwork m_work1y6m m_work2y6m m_work3y6m m_work4y6m m_work21y

local factor_meduc mb_ed1y6m mb_ed2y6m mb_ed3y6m mb_ed4y6m mb_ed8y 

local factor_fhome f_home1y6m f_home2y6m f_home3y6m f_home4y6m f_home8y 

local factor_educ sch_hs30y si30y_techcc_att si30y_univ_comp years_30y 

local factor_emp si30y_works_job si21y_inc_labor si30y_inc_labor si21y_inc_trans_pub si30y_inc_trans_pub /*si30y_inc_trans_pub_dummy*/

local factor_crime ad34_fel ad34_mis si30y_adlt_totinc 

local factor_tad si30y_cig_num drink_days drink_binge_days si34y_drugs /*si30y_cig_daily */

local factor_shealth si30y_subj_health si34y_subj_health

local factor_hyper si34y_sys_bp si34y_dia_bp si34y_prehyper si34y_hyper 

local factor_chol si34y_chol_hdl si34y_dyslipid

local factor_diabetes si34y_hemoglobin si34y_prediab si34y_diab

local factor_obese si34y_bmi si34y_obese si34y_sev_obese si34y_whr si34y_obese_whr si34y_fram_p1

local factor_bsi bsi_tsom BSISom_T bsi_tdep BSIDep_T bsi_tanx BSIAnx_T bsi_thos BSIHos_T bsi_tgsi B18GSI_T bsi_rsom BSISomRw bsi_rdep BSIDepRw bsi_ranx BSIAnxRw bsi_rhos BSIHosRw


local flip_variables si34y_chol_hdl si21y_inc_trans_pub si30y_inc_trans_pub /*si30y_inc_trans_pub_dummy */
foreach var in `flip_variables' {
	replace `var' = `var' * -1
}

local categories iq5 iq12 iq21 achv12 achv21 home pinc mwork meduc fhome educ emp crime tad shealth hyper chol diabetes obese bsi


* determine if we need to deal with ABC
count if abc == 1
if r(N)>0 local abcfactor = 1
else local abcfactor = 0

* determine if we need to deal with CARE
count if abc == 0
if r(N)>0 local carefactor = 1
else local carefactor = 0

* update locals if CARE is part of the sample
if `carefactor' == 1 {
local factor_pinc p_inc1y6m p_inc2y6m p_inc3y6m p_inc4y6m 
local factor_achv12 ach5y6m ach6y ach6y6m ach7y ach7y6m ach8y ach8y6m 
}

foreach cat in `categories' {
	local new_cat_local 
	foreach var in `factor_`cat'' {
		if (`carefactor' == 0 & `abcfactor' == 1) | (`carefactor' == 1 & `abcfactor' == 0) {
			sum `var'
			if r(N) != 0 {
				replace `var' = (`var' - r(mean))/r(sd)
				local new_cat_local `new_cat_local' `var'
			}
		}
		
		if `carefactor' == 1 & `abcfactor' == 1 {
			count if abc == 1 & !missing(`var')
			local acount = r(N)
			count if abc == 0 & !missing(`var')
			local ccount = r(N)
			if `acount' != 0 & `ccount' != 0 {
				sum `var'
				replace `var' = (`var' - r(mean))/r(sd)
				local new_cat_local `new_cat_local' `var'
			}
		}
	}
	*di as error "factor_`cat': `new_cat_local'"
	capture factor `new_cat_local', factors(1)
	if !_rc	{
		capture predict factor_`cat'
		if _rc gen factor_`cat' = .
		}
	else gen factor_`cat' = .
}

keep new_id factor_*
sum factor_*
tempfile factors
save `factors', replace

use `prefactor', clear
merge 1:1 new_id using `factors', nogen
drop new_id

