local read 	read5y6m read6y read6y6m read7y read7y6m read8y read8y6m read12y read15y read21y
local math 	math5y6m math6y math6y6m math7y math7y6m math8y math8y6m math12y math15y math21y
local iq 	iq2y iq3y iq3y6m iq4y iq4y6m iq5y iq6y iq6y6m iq7y iq8y iq12y iq15y iq21y vrb2y vrb3y vrb3y6m vrb4y vrb4y6m vrb5y vrb6y vrb6y6m vrb7y vrb8y vrb12y vrb15y vrb21y prf2y prf3y prf3y6m prf4y prf4y6m prf5y prf6y prf6y6m prf7y prf8y prf12y prf15y prf21y
local ach	`read' `math'

local late	Rrlatemathrfullearly Rrlatemathrfullmed Rrlatemathrfullteen Rrlatemathrfulllate Rrlatemathrprfearly Rrlatemathrprfmed Rrlatemathrprfteen Rrlatemathrprflate Rrlatemathrvrbearly Rrlatemathrvrbmed Rrlatemathrvrbteen Rrlatemathrvrblate
local teen	Rrteenmathrfullearly Rrteenmathrfullmed Rrteenmathrfullteen Rrteenmathrprfearly Rrteenmathrprfmed Rrteenmathrprfteen Rrteenmathrvrbearly Rrteenmathrvrbmed Rrteenmathrvrbteen

local home	home_affect0y6m home_abspun0y6m home_orgenv0y6m home_toys0y6m home_orgenv8y home_devstm8y home_leng8y home_absrst8y home_exper4y6m home_mature4y6m home_phyenv4y6m home_abspun4y6m home_affect4y6m home_masc4y6m home_indep4y6m home4y6m home_exper3y6m home_mature3y6m home_phyenv3y6m home_abspun3y6m home_affect3y6m home_masc3y6m home_indep3y6m home3y6m home_affect2y6m home_abspun2y6m home_orgenv2y6m home_toys2y6m home_minvol2y6m home_oppvar2y6m home2y6m home_affect1y6m home_abspun1y6m home_orgenv1y6m home_toys1y6m home_minvol1y6m home_oppvar1y6m home1y6m home_indep8y home_emotin8y home_oppvar8y home_phyenv8y home_toys8y home8y home_oppvar0y6m home0y6m home_minvol0y6m

local cbi	new_cbi_ho5y6m new_cbi_de5y6m new_cbi_di5y6m new_cbi_iv5y6m new_cbi_ho5y9m new_cbi_de5y9m new_cbi_di5y9m new_cbi_iv5y9m new_cbi_ho6y new_cbi_de6y new_cbi_di6y new_cbi_iv6y new_cbi_ho6y6m new_cbi_de6y6m new_cbi_di6y6m new_cbi_iv6y6m new_cbi_ho7y new_cbi_de7y new_cbi_di7y new_cbi_iv7y new_cbi_ho7y6m new_cbi_de7y6m new_cbi_di7y6m new_cbi_iv7y6m new_cbi_ho8y new_cbi_de8y new_cbi_di8y new_cbi_iv8y new_cbi_ho12y new_cbi_de12y new_cbi_di12y new_cbi_iv12y
local walker	new_wlkr_act8y new_wlkr_withd8y new_wlkr_dst8y new_wlkr_peer8y new_wlkr_immt8y wlkr_tot
local kr	new_kr_withd2y new_kr_dst2y new_kr_withd2y6m new_kr_dst2y6m new_kr_withd3y new_kr_dst3y new_kr_withd4y new_kr_dst4y new_kr_withd5y new_kr_dst5y new_kr_withd6y6m new_kr_dst6y6m new_kr_withd7y new_kr_dst7y
local ibr	ibr_task2y ibr_actv2y ibr_coop2y ibr_task1y6m ibr_actv1y6m ibr_coop1y6m ibr_sociab1y6m ibr_task1y ibr_actv1y ibr_coop1y ibr_sociab1y ibr_task0y6m ibr_actv0y6m ibr_coop0y6m ibr_sociab0y6m ibr_task0y3m ibr_actv0y3m ibr_sociab0y3m ibr_task0y9m ibr_actv0y9m ibr_sociab0y9m ibr_sociab2y
local se	`cbi' `walker' `kr' `ibr'

local school	si30y_techcc_att si30y_univ_comp sch_hs30y years_30y
local jobatt	J_WorkWell J_Lose J_StayAway J_Stress J_Trouble J_Boss J_Worry J_Satisfied J_Others
local jobsat	commsd coworkerssd fringebensd supervisionsd natworksd opprocsd paysd promotionsd contrewsd jbsttotsd
local sped	ever_sped tot_sped ever_ret tot_ret
local emp	si30y_works_job si21y_inc_labor si30y_inc_labor si21y_inc_trans_pub si30y_inc_trans_pub
local edemp	`school' `jobatt' `jobsat' `sped' `emp' 
local ed	`school' `sped'
local emp	`emp' `jobatt' `jobsat'

foreach v in `sped' {
	replace `v' = -1 * `v'
}

replace si21y_inc_trans_pub = -1*si21y_inc_trans_pub
replace si30y_inc_trans_pub	= -1*si30y_inc_trans_pub

// Removed: m_inc0y 	
local p_inc	p_inc0y	p_inc1y6m	p_inc2y6m	p_inc3y6m	p_inc4y6m	p_inc8y	p_inc12y	p_inc15y	p_inc21y	pi_inc_trans12y	pi_inc_trans15y	m_inc_trans21y		

replace pi_inc_trans12y = -1*pi_inc_trans12y	
replace pi_inc_trans15y = -1*pi_inc_trans15y
replace m_inc_trans21y = -1*m_inc_trans21y

local p_edu	mb_ed1y6m	mb_ed2y6m	mb_ed3y6m	mb_ed4y6m	mb_ed8y	m_ed0y	m_ed1y6m	m_ed2y6m	m_ed3y6m	m_ed4y6m	m_ed8y	m_ed12y	m_ed15y																
local parent	`p_inc' `p_edu'
/* Removed: PE_NECK	PE_NEURO	PE_NOSE	PE_HYD	PE_ORIENT	PE_VOICE	PE_BREAST	PE_MAST	PE_PINNA	PE_TYMP		PE_PUPIL	PE_SCLERA
			PE_AUS	PE_ABD	PE_PALP	PE_LAXI	PE_LFEM	PE_LHEAD PE_FLMOUTH 	PE_ORO	PE_TONSIL 	PE_BSTEM	PE_COORD	PE_GAIT	PE_LOEX		PE_UPEX
			si34y_hprob_chol  si34y_hprob_heartatt si34y_hprob_othheart
			si34y_hprob_cancer  si34y_hprob_memory si34y_hprob_sickle si34y_hprob_sickle_p  si34y_hprob_stroke
*/
local reverse sint30_078	sint30_023	poorhlth	physhlth	PE_NUT	PE_POST	PE_PULS	PE_RESP	PE_TEMP	PE_CARDIO	PE_CHGEN	PE_HEAD	PE_JOINT	PE_SKIN	PE_AUD PE_EYEBALL	PE_FUNDI	PE_LOWTEETH	PE_UPTEETH PE_REFL	si30y_subj_health si34y_subj_health	si34y_vitd_def	si34y_obese_whr	si34y_fram_p1	si34y_bmi	si34y_obese	si34y_sev_obese	si34y_whr	si34y_hprob_othheart_p	HAVARTH2	si34y_hprob_orthop_p	si34y_hprob_asthma_p	si34y_hprob_cancer_p	si34y_hprob_diabetes_p	si34y_hprob_heartatt_p	si34y_hprob_bloodpr_p	si34y_hprob_chol_p	PREDIAB1_R	si34y_hprob_stroke_p	PSH_APPEN	PSH_CHOLEC	PSH_ECT	PSH_HYST	PSH_ORTHO	si34y_hprob_orthop	si34y_hprob_asthma	si34y_hprob_diabetes	si34y_hprob_bloodpr	si34y_diab	si34y_hemoglobin	si34y_prediab	si34y_dia_bp	si34y_sys_bp	si34y_prehyper	si34y_hyper	PAINACT2	si34y_dyslipid	sint30_078	sint30_023	poorhlth	physhlth
local child_health bmi0y bmi0y3m bmi0y6m bmi0y9m bmi1y bmi1y6m bmi2y bmi2y6m bmi3y bmi4y bmi5y bmi8y hospitl7 chsick7

// Removed: si21y_risk32 
local risk alc_t drug_t	ms_t tob_t si30y_crack_num si30y_coc_ever_reg si30y_coc_num si30y_marj_reg	si34y_marj_reg si30y_marj_num si21y_risk29 si30y_marj_freq si21y_risk34 cas_mbdrugs12y	cas_mbtralc12y	si21y_risk6	si21y_cig_reg	si21y_risk21	si21y_risk25	si30y_cig_ever_reg	si30y_cig_num	si30y_drink_binge_days	si34y_drink_binge_days	si30y_drink_days	si34y_drink_days	drink_binge_days	drink_days	si34y_drugs	
// Removed: 	dsm_hi_t	dsm_ina_t	PE_ALERT	PE_DISTRESS 
local mental bsi_tis	bsi_toc	bsi_tpar	bsi_tpho	bsi_tpsd	bsi_tpst	bsi_tpsy	dsm_adh_t	dsm_ant_t	dsm_anx_t	dsm_avd_t	dsm_dep_t	dsm_som_t	dsm_adh_pct	dsm_ant_pct	dsm_anx_pct	dsm_avd_pct	dsm_dep_pct dsm_hi_pct dsm_ina_pct	dsm_som_pct agg_t	anx_t	att_t	ext_t	int_t	intr_t	rule_t	som_t	tht_t	with_t	totp_t	crit_t	B18Anx_T	B18Dep_T	B18Som_T	B18GSI_T	PSYC_ANX	PSYC_NC	PSYC_DEP	PSYC_INS	si34y_hprob_mental	QLMENTL2	PSYC_SUIC	QLSTRES2	bsi_ranx	BSIAnxRw	bsi_rdep	BSIDepRw	bsi_rgsi	B18Raw	bsi_rhos	BSIHosRw	bsi_rsom	BSISomRw	bsi_tanx	BSIAnx_T	bsi_tdep	BSIDep_T	bsi_thos	BSIHos_T	bsi_tsom	BSISom_T	bsi_tgsi

foreach v in `reverse' {
	replace `v' = -1 * `v'
}

foreach v in `child_health' {
	replace `v' = -1 * `v'
}

foreach v in `risk' {
	replace `v' = -1 * `v'
}

foreach v in `mental' {
	replace `v' = -1 * `v'
}

local positive si21y_phys_days	si34y_phys_days	modpact	modpatimhrs	modpaday vigpact vigpatimhrs	vigpaday	jobactiv	CMP_ALT	CMP_AST	CMP_ALB	CMP_ALB_GLOB	CMP_ALKPHOS	CMP_BILI	CMP_CA	CMP_CO2	CMP_CL	CMP_CREAT	CMP_GLOB	CMP_GLUCOSE	CMP_K	CMP_PROT	CMP_NA	CMP_UREA	CBC_BASO	CBC_EOSINO	CBC_HCT	CBC_HEMOG	CBC_LYMPHO	CBC_MCV	CBC_MCHC	CBC_MCH	CBC_MONO	CBC_NEUTRO	CBC_PLATELET	CBC_RDW	CBC_RED	CBC_WHITE	si34y_chol_hdl	QLHLTH2	si21y_hlthins	si30y_hlthins	si34y_hlthins

local health `reverse' `positive' //`risk' `mental' //`child_health' 


local crime ad34_fel ad34_mis si30y_adlt_totinc si30y_juv_fel ncharges narrests nfel nmis nviol nprop ndrug nothr
//foreach v in `crime' {
//	replace `v' = -1 * `v'
//}

local outcome_categories iq ach home se ed emp parent health crime

local iq_name 		IQ
local ach_name 		Achievement
local home_name 	Parenting
local se_name 		Social-emotional
local ed_name 		Education
local emp_name		Employment
local parent_name 	Parental income
local health_name 	Health
local crime_name 	Crime
