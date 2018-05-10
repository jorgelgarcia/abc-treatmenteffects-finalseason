

local categories iq ach se parenting mlabor education employment crime risk health mentalhealth all

local iq_name 			IQ
local ach_name 			Achievement
local parenting_name 		Parenting
local mlabor_name 		Parental Income
local fhome_name 		Father Present
local education_name 		Education
local employment_name 		Employment
local crime_name 		Crime
local risk_name 		Risky Behavior
local health_name 		Health
local married_name 		Married
local mentalhealth_name 	Mental Health
local all_name			All
local se_name			Social-emotional

# delimit ;
local iq 
iq2y
iq3y
iq3y6m
iq4y
iq4y6m
iq5y
iq6y6m
iq7y
iq8y
iq12y
iq15y
iq21y
factor_iq5y
factor_iq12y
factor_iq21y;

local iqnew 
iq2y
iq3y
iq3y6m
iq4y
iq4y6m
iq5y
iq12y;

local factor_iq5y 
iq2y 
iq3y
iq3y6m
iq4y
iq4y6m
iq5y;
local factor_iq12y
iq6y6m
iq7y
iq8y
iq12y;
local factor_iq21y
iq15y
iq21y;

local ach
ach5y6m
ach6y
ach6y6m
ach7y
ach7y6m
ach8y
ach8y6m
achy12y
ach15y
ach21y
factor_ach12y 
factor_ach21y;

local achnew
ach5y6m
ach6y
ach7y6m
ach8y
ach8y6m;

local factor_ach12y
ach5y6m
ach6y
ach6y6m
ach7y
ach7y6m
ach8y
ach8y6m
achy12y;

local factor_ach21y
ach15y
ach21y;

local parenting
home0y6m
home1y6m
home2y6m
home3y6m
home4y6m
home8y
factor_home;

local newparenting
home0y6m
home1y6m
home2y6m
home3y6m
home4y6m;

local factor_home
home0y6m
home1y6m
home2y6m
home3y6m
home4y6m
home8y;

local mlabor
p_inc1y6m
p_inc2y6m
p_inc3y6m
p_inc4y6m
p_inc8y
p_inc12y
p_inc15y
p_inc21y
factor_pinc
m_work1y6m
m_work2y6m
m_work3y6m
m_work4y6m
m_work21y
factor_mwork;

local factor_pinc
p_inc1y6m
p_inc2y6m
p_inc3y6m
p_inc4y6m
p_inc8y
p_inc12y
p_inc15y
p_inc21y;
local factor_mwork
m_work1y6m
m_work2y6m
m_work3y6m
m_work4y6m
m_work21y;

local fhome
f_home1y6m
f_home2y6m
f_home3y6m
f_home4y6m
f_home8y
factor_fhome;

local factor_fhome
f_home1y6m
f_home2y6m
f_home3y6m
f_home4y6m
f_home8y;

local education
sch_hs30y
si30y_techcc_att
si30y_univ_comp
years_30y
ever_sped
tot_sped
ever_ret
tot_ret
factor_educ
;

local factor_educ
sch_hs30y
si30y_techcc_att
si30y_univ_comp
years_30y
ever_sped
tot_sped
ever_ret
tot_ret;

local employment
si30y_works_job
si21y_inc_labor
si30y_inc_labor
factor_emp;

local employmentnew
si30y_works_job
si30y_inc_labor;

local factor_emp
si30y_works_job
si21y_inc_labor
si30y_inc_labor;

local married
si30y_mar;

local crime
ad34_fel
ad34_mis
si30y_adlt_totinc
factor_crime;

local factor_crime
ad34_fel
ad34_mis
si30y_adlt_totinc;

local risk
si30y_cig_num
drink_days
drink_binge_days
si34y_drugs
factor_tad;

local factor_tad
si30y_cig_num
drink_days
drink_binge_days
si34y_drugs;

local health
si30y_subj_health
si34y_subj_health
factor_shealth
si34y_sys_bp
si34y_dia_bp
si34y_prehyper
si34y_hyper
factor_hyper
si34y_chol_hdl
si34y_dyslipid
factor_chol
si34y_hemoglobin
si34y_prediab
si34y_diab
factor_diabetes
si34y_bmi
si34y_obese
si34y_sev_obese
si34y_whr
si34y_obese_whr
si34y_fram_p1
factor_obese;

local factor_shealth
si30y_subj_health
si34y_subj_health;
local factor_hyper
si34y_sys_bp
si34y_dia_bp
si34y_prehyper
si34y_hyper;
local factor_chol
si34y_chol_hdl
si34y_dyslipid;
local factor_diabetes
si34y_hemoglobin
si34y_prediab
si34y_diab;
local factor_obese
si34y_bmi
si34y_obese
si34y_sev_obese
si34y_whr
si34y_obese_whr
si34y_fram_p1;

local mentalhealth
bsi_tsom
BSISom_T
bsi_tdep
BSIDep_T
bsi_tanx
BSIAnx_T
bsi_thos
BSIHos_T
bsi_tgsi
B18GSI_T
factor_bsi;

local mentalhealthnew
bsi_tsom
bsi_tdep
bsi_tanx
bsi_thos
bsi_tgsi;

local factor_bsi
bsi_tsom
BSISom_T
bsi_tdep
BSIDep_T
bsi_tanx
BSIAnx_T
bsi_thos
BSIHos_T
bsi_tgsi
B18GSI_T;

local se
ibr_task0y3m 
ibr_actv0y3m 
ibr_sociab0y3m 
ibr_task0y6m 
ibr_actv0y6m 
ibr_sociab0y6m
ibr_coop0y6m  
ibr_task0y9m 
ibr_actv0y9m 
ibr_sociab0y9m 
ibr_task1y 
ibr_actv1y 
ibr_sociab1y 
ibr_coop1y 
ibr_task1y6m 
ibr_actv1y6m 
ibr_sociab1y6m 
ibr_coop1y6m 
ibr_task2y 
ibr_actv2y 
ibr_sociab2y
ibr_coop2y ;


local senew
ibr_task0y6m 
ibr_actv0y6m 
ibr_sociab0y6m
ibr_task1y 
ibr_actv1y 
ibr_sociab1y 
ibr_task1y6m 
ibr_actv1y6m 
ibr_sociab1y6m ;

# delimit cr

local all `iq' `ach' `se' `parenting' `mlabor' `education' `employment' `crime' `risk' `health' `mentalhealth'


//// The following factors constructed May 10, 2018 to update the non-parametric tests
# delimit ;

local iq_updated
iq2y
iq3y
iq3y6m
iq4y
iq4y6m
iq5y
iq12y;

local ach_updated
ach5y6m
ach6y
ach7y6m
ach8y
ach8y6m;

local se_updated 
bsi_tsom
bsi_tdep
bsi_tanx
bsi_thos
bsi_tgsi
ibr_task0y6m 
ibr_actv0y6m 
ibr_sociab0y6m
ibr_task1y 
ibr_actv1y 
ibr_sociab1y 
ibr_task1y6m 
ibr_actv1y6m 
ibr_sociab1y6m;


local mlabor_updated 
p_inc8y
m_work1y6m
m_work2y6m
m_work3y6m
m_work4y6m;

local parent_updated 
home0y6m
home1y6m
home2y6m
home3y6m
home4y6m;

local crime_updated
ad34_fel
ad34_mis
si30y_adlt_totinc;

local health_updated
si30y_subj_health
si34y_sys_bp
si34y_dia_bp
si34y_prehyper
si34y_hyper
si34y_chol_hdl
si34y_dyslipid
si34y_hemoglobin
si34y_prediab
si34y_diab
si34y_bmi
si34y_obese
si34y_sev_obese
si34y_whr
si34y_obese_whr
si34y_fram_p1;

local risk_updated
si30y_cig_num
drink_days
drink_binge_days
si34y_drugs;

local emp_updated
si30y_works_job
si30y_inc_labor;

local edu_updated
sch_hs30y
si30y_techcc_att
si30y_univ_comp
years_30y
tot_sped
tot_ret;

local age5_updated
iq2y
iq3y
iq3y6m
iq4y
iq4y6m
iq5y
ibr_task0y6m 
ibr_actv0y6m 
ibr_sociab0y6m
ibr_task1y 
ibr_actv1y 
ibr_sociab1y 
ibr_task1y6m 
ibr_actv1y6m 
ibr_sociab1y6m
m_work1y6m
m_work2y6m
m_work3y6m
m_work4y6m
home0y6m
home1y6m
home2y6m
home3y6m
home4y6m;

local age15_updated
ach5y6m
ach6y
ach7y6m
ach8y
ach8y6m
iq12y
p_inc8y
tot_sped
tot_ret;

local age34_updated
bsi_tsom
bsi_tdep
bsi_tanx
bsi_thos
bsi_tgsi
si34y_sys_bp
si34y_dia_bp
si34y_hyper
ad34_fel
ad34_mis
si30y_adlt_totinc
si34y_drugs
si30y_works_job
si30y_inc_labor
sch_hs30y
si30y_techcc_att
si30y_univ_comp
years_30y;

local all_updated
`age5_updated'
`age15_updated'
`age34_updated';
