# delimit ;

local reverse
overw40
h_prob27
cigs27
M0298
M0245
charges27 
charges40 
felcrime
sch_nsus
sch_nrep
sch_eversped
cunemployed
mbedridden
bmiobese
whrobese
prehyp
hypert
tchigh
hcrp
hhba1c
pdaysunh
diabetes
stroke
heartd
cigslife
cigsnow
avgdrinks
hdrugs
ondays;

# delimit cr
foreach v in `reverse' {
	replace `v' = -1 * `v'
}

local categories iq ach se parenting mlabor education employment crime risk health all

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
local all_name			All
local se_name			Social-emotional

# delimit ;
local iq 
sb_iq_3
ppvt3
leit3
sb_iq_4
ppvt4
leit4
sb_iq_5
ppvt5
leit5
sb_iq_6
ppvt6
leit6
sb_iq_7
ppvt7
leit7
sb_iq_8
ppvt8
leit8
sb_iq_9
ppvt9
leit9
sb_iq_10
sb_iq_11
sb_iq_12
wisc_iq_14
fint 
cint
gint
factor_iq5y
factor_iq14y
factor_iq50y;

local factor_iq5y 
sb_iq_3
ppvt3
leit3
sb_iq_4
ppvt4
leit4
sb_iq_5
ppvt5
leit5;
local factor_iq14y
sb_iq_6
ppvt6
leit6
sb_iq_7
ppvt7
leit7
sb_iq_8
ppvt8
leit8
sb_iq_9
ppvt9
leit9
sb_iq_10
sb_iq_11
sb_iq_12
wisc_iq_14;
local factor_iq50y
fint 
cint
gint;

local ach
read7
math7
read8
math8
read9
math9
read10
math10
read11
math11
read14
math14
read19
math19
read27
math27
read40
math40
factor_ach14y 
factor_ach40y;

local factor_ach14y
read7
math7
read8
math8
read9
math9
read10
math10
read11
math11
read14
math14;

local factor_ach40y
read19
math19
read27
math27
read40
math40;

local se
yrs_soc6
yrs_emo6
yrs_soc7
yrs_emo7
yrs_soc8
yrs_emo8
yrs_soc9
yrs_emo9
pbi_acad6 
pbi_acad7 
pbi_acad8 
pbi_acad9 
pbi_cond6 
pbi_cond7 
pbi_cond8 
pbi_cond9 
pbi_emo6 
pbi_emo7 
pbi_emo8 
pbi_emo9 
pbi_dep6 
pbi_dep7 
pbi_dep8 
pbi_dep9 
pbi_beh6 
pbi_beh7 
pbi_beh8 
pbi_beh9
postrait1
postrait2
postrait3
grit
factor_se50y
;
local factor_se50y
postrait1
postrait2
postrait3
grit
;


local parenting
suppAggress_last
encVerbal_last
comrade_last
devpt_last
strictness_last
schooldedication_last
schoolinteraction_last
factor_pari;

local factor_pari
suppAggress_last
encVerbal_last
comrade_last
devpt_last
strictness_last
schooldedication_last
schoolinteraction_last;

local mlabor
m_work_base
m_work15
ses
factor_mwork;

local factor_mwork
m_work_base
m_work15;

local education
hs40
sch_nsus
sch_nrep
sch_eversped
A4808
M0567
factor_educ;

local factor_educ
hs40
sch_nsus
sch_nrep
sch_eversped
A4808
M0567;

local employment
incomy27
incomy40
works
cunemployed
totmonthlypay
factor_emp
monthearn2;

local factor_emp
incomy27
incomy40
cunemployed
works
totmonthlypay
monthearn2;

local crime
charges27 
charges40 
felcrime
tmisdarr50
tfelarr50
tfelcon50
factor_crime;

local factor_crime
charges27 
charges40 
tmisdarr50
tfelarr50
tfelcon50
felcrime;

local risk
cigs27
cigslife
factor_tad
cigsnow
avgdrinks;

local factor_tad
cigs27
cigslife
cigsnow
avgdrinks
hdrugs;

local health
healthy40
h_prob27
exam27
bmiobese
whrobese
hypert
pfnormal
tchigh
hcrp
hhba1c
pdaysunh
ghealth
diabetes
stroke
heartd
mbedridden
ondays;

# delimit cr

local all `iq' `ach' `se' `parenting' `mlabor' `education' `employment' `crime' `risk' `health' 
