# delimit ;

local reverse
idle18y
sch_eversped18y
sch_hs18y 
cigs18y
ye8_youth_18y
chlth_impdaynum4y_i3 
chlth_impbednum4y_i4 
chlth_impdaynum5y_i3 
chlth_impbednum5y_i4
inthlth_asthma2y6m 
inthlth_asthma3y
inthlth_hearingsev2y6m 
inthlth_hearingsev3y
inthlth_othcardio2y6m 
inthlth_othcardio3y
achp_sum3y 
achp_ext3y 
achp_int3y 
achp_wdrn3y 
achp_dprs3y 
achp_sleep3y 
achp_soma3y 
achp_aggr3y 
achp_destroy3y 
achp_oths3y 
achp_prblmt3y 
achp_extt3y 
achp_intt3y 
achp_hyp8y 
;



# delimit cr
foreach v in `reverse' {
	replace `v' = -1 * `v'
}

local categories iq ach se parenting mlabor education risk health all


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
iq3y 
iq5y 
iq8y 
iq18y
factor_iq;

local factor_iq 
iq3y 
iq5y 
iq8y 
iq18y;

local ach
read8y 
read18y 
math8y 
math18y
factor_ach;

local factor_ach
read8y 
read18y 
math8y 
math18y;

local parenting
homto_12_sumscore
homto_36_sumscore
fes8y
factor_home;

local factor_home
homto_12_sumscore
homto_36_sumscore;

local mlabor
f_work40wk 
f_work1y 
f_work2y 
f_work3y 
f_work4y 
f_work5y 
f_work6y6m 
f_work8y
m_work40wk 
m_work4m 
m_work8m 
m_work1y 
m_work1y6m 
m_work2y 
m_work2y6m 
m_work3y 
m_work4y 
m_work5y 
m_work6y6m 
m_work8y
hh_inc1y
hh_inc2y
hh_inc3y
hh_inc4y
hh_inc5y
hh_inc6y6m
hh_inc8y
factor_mwork
factor_fwork
factor_hhinc;

local factor_mwork
m_work40wk 
m_work4m 
m_work8m 
m_work1y 
m_work1y6m 
m_work2y 
m_work2y6m 
m_work3y 
m_work4y 
m_work5y 
m_work6y6m 
m_work8y;
local factor_fwork
f_work40wk 
f_work1y 
f_work2y 
f_work3y 
f_work4y 
f_work5y 
f_work6y6m 
f_work8y;
local factor_hhinc
hh_inc1y
hh_inc2y
hh_inc3y
hh_inc4y
hh_inc5y
hh_inc6y6m
hh_inc8y;

local education
sch_eversped18y
sch_hs18y 
factor_educ
;

local factor_educ
sch_eversped18y
sch_hs18y ;

local employment
inc18y 
idle18y
factor_emp;

local factor_emp
inc18y 
idle18y;

local risk
cigs18y
ye8_youth_18y
factor_tad;

local factor_tad
cigs18y
ye8_youth_18y;

local health
chlth_impdaynum4y_i3 
chlth_impbednum4y_i4 
chlth_impdaynum5y_i3 
chlth_impbednum5y_i4
chlth_mr8
inthlth_asthma2y6m 
inthlth_asthma3y
inthlth_hearingsev2y6m 
inthlth_hearingsev3y
inthlth_othcardio2y6m 
inthlth_othcardio3y
factor_hlth;

local factor_hlth
chlth_impdaynum4y_i3 
chlth_impbednum4y_i4 
chlth_impdaynum5y_i3 
chlth_impbednum5y_i4
chlth_mr8
inthlth_asthma2y6m 
inthlth_asthma3y
inthlth_hearingsev2y6m 
inthlth_hearingsev3y
inthlth_othcardio2y6m 
inthlth_othcardio3y;

local se
bayley_mdi1y 
bayley_pdi1y 
bayley_mdi2y 
bayley_pdi2y
orig_rapst_open6y6m 
orig_rapst_cons6y6m 
orig_rapst_stab6y6m 
orig_rapst_open8y 
orig_rapst_cons8y 
orig_rapst_stab8y
achp_sum3y 
achp_ext3y 
achp_int3y 
achp_wdrn3y 
achp_dprs3y 
achp_sleep3y 
achp_soma3y 
achp_aggr3y 
achp_destroy3y 
achp_oths3y 
achp_prblmt3y 
achp_extt3y 
achp_intt3y 
achp_hyp8y 
ach_open5y 
ach_cons5y 
ach_extr5y 
ach_agre5y 
ach_stab5y 
ach_hlth5y 
ach_emot5y 
ach_open8y 
ach_cons8y 
ach_extr8y 
ach_agre8y 
ach_stab8y 
ach_hlth8y 
ach_emot8y
factor_ache
factor_raps
factor_bayley;

local factor_ache
achp_sum3y 
achp_ext3y 
achp_int3y 
achp_wdrn3y 
achp_dprs3y 
achp_sleep3y 
achp_soma3y 
achp_aggr3y 
achp_destroy3y 
achp_oths3y 
achp_prblmt3y 
achp_extt3y 
achp_intt3y 
achp_hyp8y 
ach_open5y 
ach_cons5y 
ach_extr5y 
ach_agre5y 
ach_stab5y 
ach_hlth5y 
ach_emot5y 
ach_open8y 
ach_cons8y 
ach_extr8y 
ach_agre8y 
ach_stab8y 
ach_hlth8y 
ach_emot8y;

local factor_bayley
bayley_mdi1y 
bayley_pdi1y 
bayley_mdi2y 
bayley_pdi2y;

local factor_raps
orig_rapst_open6y6m 
orig_rapst_cons6y6m 
orig_rapst_stab6y6m 
orig_rapst_open8y 
orig_rapst_cons8y 
orig_rapst_stab8y;


# delimit cr
local all `iq' `ach' `se' `parenting' `mlabor' `education' `risk' `health' `mentalhealth'
