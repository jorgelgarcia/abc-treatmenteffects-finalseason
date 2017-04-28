// rename some variables
foreach v in auth hostl demo dpnd scls noaggr isltd supsex maritl nohome rage verb egal comrde {
	rename pari_`v' pari_`v'0y6m
}
// Reverse code Walker variables so that a higher score is more desirable (less problematic)
// Total scale determined from ABC_S_UNC_Walker.pdf

gen new_wlkr_act8y = 26-wlkr_act8y
copydesc wlkr_act8y new_wlkr_act8y
gen new_wlkr_withd8y = 14-wlkr_withd8y
copydesc wlkr_withd8y new_wlkr_withd8y 
gen new_wlkr_dst8y = 14-wlkr_dst8y
copydesc wlkr_dst8y new_wlkr_dst8y
gen new_wlkr_peer8y = 25-wlkr_peer8y
copydesc wlkr_peer8y new_wlkr_peer8y
gen new_wlkr_immt8y = 19-wlkr_immt8y
copydesc wlkr_immt8y new_wlkr_immt8y

// Reverse code CBI variables for introversion, dependence, hostility, distractible so higher score is more desirable
// (6*questions - current score) since scale from 1 to 5

local ages 5y6m 5y9m 6y 6y6m 7y 7y6m 8y 12y

foreach a in `ages' {
	gen new_cbi_ho`a' = 6*3 - cbi_ho`a'
	copydesc cbi_ho`a' new_cbi_ho`a'
	gen new_cbi_de`a' = 6*3 - cbi_de`a'
	copydesc cbi_de`a' new_cbi_de`a'
	gen new_cbi_di`a' = 6*3 - cbi_di`a'
	copydesc cbi_di`a' new_cbi_di`a'
	gen new_cbi_iv`a' = 6*3 - cbi_iv`a'
	copydesc cbi_iv`a' new_cbi_iv`a'
}



/*
Reverse code EASI variables for emotionality, fear, anger, tempo, vigor, control, 
decisive, sensation, & persistence (all variables except sociability)
A higher score indicates more calm, less fear, less anger, more slowed down, 
less vigorous, more control, more decisive, less thrill-seeking, more persistent
(6*questions - current score) since scale from 1 to 5
*/
gen new_easy_gen = 6*5 - easy_gen
label var new_easy_gen "easy endpt factor1/emotionality-general"
gen new_easy_fear = 6*5 - easy_fear
label var new_easy_fear "easy endpt factor2/emotionality-fear"
gen new_easy_ang = 6*5 - easy_ang
label var new_easy_ang "easy endpt factor3/emotionality-anger"
gen new_easy_temp = 6*5 - easy_temp
label var new_easy_temp "easy endpt factor4/activity-tempo"
gen new_easy_vig = 6*5 - easy_vig
label var new_easy_vig "easy endpt factor5/activity-vigor"
gen new_easy_cont = 6*5 - easy_cont
label var new_easy_cont "easy endpt factor7/impulsitivity-control"
gen new_easy_deci = 6*5 - easy_deci
label var new_easy_deci "easy endpt factor8/impulsitivity-decisive"
gen new_easy_sens = 6*5 - easy_sens
label var new_easy_sens "easy endpt factor9/impulse-sensation"
gen new_easy_pers = 6*5 - easy_pers
label var new_easy_pers "easy endpt factor10/impulse-perservere"

// Reverse code for Kohn-Rosman for anxious/withdrawn and distractible/disruptive so a higher score is more desirable
// (7 - current score) since scale from 1 to 6 based on the mean score
local ages2 2y 2y6m 3y 4y 5y 6y6m 7y

foreach a in `ages2' {
	gen new_kr_withd`a' = 7 - kr_withd`a'
	copydesc kr_withd`a' new_kr_withd`a'
	gen new_kr_dst`a' = 7 - kr_dst`a'
	copydesc kr_dst`a' new_kr_dst`a' 
}

// Creating new PARI factors (autho, demo, hostl) based on documentation (sum subscales, did not do +50)

egen new_pari_auth0y6m = rowtotal(pari_dpnd0y6m pari_scls0y6m pari_noaggr0y6m pari_isltd0y6m pari_supsex0y6m)
replace new_pari_auth0y6m=. if new_pari_auth0y6m==0
label var new_pari_auth0y6m "Appropriate sum of subscales for authority factor, 0y6m"
egen new_pari_hostl0y6m = rowtotal(pari_maritl0y6m pari_nohome0y6m pari_rage0y6m)
replace new_pari_hostl0y6m=. if new_pari_hostl0y6m==0
label var new_pari_hostl0y6m "Appropriate sum of subscales for hostility factor, 0y6m"
egen new_pari_demo0y6m = rowtotal(pari_verb0y6m pari_egal0y6m pari_comrde0y6m)
replace new_pari_demo0y6m=. if new_pari_demo0y6m==0
label var new_pari_demo0y6m "Appropriate sum of subscales for democratic factor, 0y6m"

egen new_pari_auth1y6m = rowtotal(pari_dpnd1y6m pari_scls1y6m pari_noaggr1y6m pari_isltd1y6m pari_supsex1y6m)
replace new_pari_auth1y6m=. if new_pari_auth1y6m ==0
label var new_pari_auth1y6m "Appropriate sum of subscales for authority factor, 1y6m"
egen new_pari_hostl1y6m = rowtotal(pari_maritl1y6m pari_nohome1y6m pari_rage1y6m)
replace new_pari_hostl1y6m=. if new_pari_hostl1y6m==0
label var new_pari_hostl1y6m "Appropriate sum of subscales for hostility factor, 1y6m"
egen new_pari_demo1y6m = rowtotal(pari_verb1y6m pari_egal1y6m pari_comrde1y6m)
replace new_pari_demo1y6m=. if new_pari_demo1y6m==0
label var new_pari_demo1y6m "Appropriate sum of subscales for democratic factor, 1y6m"
