


# delimit ;
local age5 
iq2y
iq3y
iq3y6m
iq4y
iq4y6m
iq5y
home0y6m
home1y6m
home2y6m
home3y6m
home4y6m
m_work1y6m
m_work2y6m
m_work3y6m
m_work4y6m
ibr_task0y6m 
ibr_actv0y6m 
ibr_sociab0y6m
ibr_task1y 
ibr_actv1y 
ibr_sociab1y 
ibr_task1y6m 
ibr_actv1y6m 
ibr_sociab1y6m;

local age15
iq12y
ach6y
ach7y6m
ach8y
ach8y6m
tot_sped;

local age34
sch_hs30y
si30y_univ_comp
years_30y
si30y_works_job
si30y_inc_labor
si30y_cig_num
bsi_tsom
bsi_tdep
bsi_tanx
bsi_thos
bsi_tgsi;


# delimit cr




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
local iqnew 
iq2y
iq3y
iq3y6m
iq4y
iq4y6m
iq5y
iq12y;

local achnew
ach5y6m
ach6y
ach7y6m
ach8y
ach8y6m;

local newparenting
home0y6m
home1y6m
home2y6m
home3y6m
home4y6m;

local mlabor
m_work1y6m
m_work2y6m
m_work3y6m
m_work4y6m;

local education
sch_hs30y
si30y_techcc_att
si30y_univ_comp
years_30y
ever_sped
tot_sped
ever_ret
tot_ret;





local employmentnew
si30y_works_job
si30y_inc_labor;




local crime
ad34_fel
ad34_mis
si30y_adlt_totinc;

local risk
si30y_cig_num
drink_days
drink_binge_days
si34y_drugs;


local health
si30y_subj_health
si34y_subj_health
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



local mentalhealthnew
bsi_tsom
bsi_tdep
bsi_tanx
bsi_thos
bsi_tgsi;


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
