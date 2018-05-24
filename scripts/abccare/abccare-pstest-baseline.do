
// settings
clear all
set more off
set matsize 11000

// parameters
set seed 1
global bootstraps 1000

// filepaths
global projects		: env projects
global klmshare		: env klmshare
global klmmexico	: env klmMexico
global abccaredata	= "${klmshare}/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv"
global repo			= "${projects}/abccare-cba"

local m_ed0y_lab 		"Mother's Yrs. of Edu."
local m_age0y_lab		"Mother's Age"
local m_iq0y_lab 		"Mother's IQ"
local m_work0y_lab		"Mother Works"
local hh_sibs0y_lab 	"Number of Siblings"
local hrabc_index_lab 	"HRI Score"
local birthyear_lab 	"Birth Year"
local male_lab			"Male"
local apgar1_lab 		"Apgar Score, 1 min."
local apgar5_lab 		"Apgar Score, 5 min."
local p_inc0y_lab		"Parental Income"
local f_home0y_lab		"Father Present"

global exogvars			m_ed0y m_age0y m_iq0y m_work0y hh_sibs0y hrabc_index		///
						abc male apgar1 apgar5 p_inc0y f_home0y

// data
cd $abccaredata
use append-abccare_iv

drop if R == 0 & RV == 1

gen ALT = (dc_mo_pre > 0 & dc_mo_pre != .)

gen fakeR = R
recode fakeR (0=1) (1=0)

// psmatch
psmatch2 fakeR male hrabc_index apgar1 apgar5 abc if (P==0 & R==0) | R==1, ///
	kernel k(epan) bwidth(20) mahalanobis(male hrabc_index apgar1 apgar5 abc)
	
pstest $exogvars 

psmatch2 fakeR male hrabc_index apgar1 apgar5 abc if (P==1 & R==0) | R==1, ///
kernel k(epan) bwidth(20) mahalanobis(male hrabc_index apgar1 apgar5 abc) 

pstest $exogvars   
