/*
Project: 	Treatment effects
Date:		April 24, 2017
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
global data	   	= "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv"
global scripts    	= "$projects/abccare-cba/scripts/"
global output      	= "$projects/abccare-cba/output/"

// variables
# delimit ;
global earlyhome		home0y6m home1y6m home2y6m;
global laterhome		home3y6m home4y6m home8y;
global homeabs			home_abspun2y6m home_abspun1y6m home_abspun0y6m
				home_abspun4y6m home_abspun3y6m;
global homephy			home_orgenv2y6m home_orgenv1y6m home_orgenv0y6m 
				home_toys2y6m home_toys1y6m home_toys0y6m
				home_orgenv8y home_phyenv8y home_toys8y;
global homemom			home_minvol2y6m home_minvol1y6m home_minvol0y6m;
global pari			new_pari_auth1y6m new_pari_demo1y6m 
				new_pari_hostl1y6m;
global parenting		earlyhome laterhome homeabs homephy homemom;
global parenting_labels		Early School-age Discipline Environment Warmth;


global iq3			sb2y sb3y mc3y6m;
global iq4			sb4y mc4y6m;
global iq5			sb5y wppsi5y;
global iq6			sb6y wis6y6m;
global iq8			mc7y wis8y;
global cog			iq3 iq4 iq5 iq8;
global cog_labels		3-years 4-years 5-years 8-years;

global readschool		math6y math7y6m math8y math8y6m math9y math12y ;	
global mathschool		read6y read7y6m read8y read8y6m read9y read12y;
global adultach			math21y read21y;
global ach			readschool mathschool adultach;
global ach_labels		Reading Math Adult;

global earlysociab		ibr_sociab0y6m ibr_sociab1y ibr_sociab1y6m;
global earlytask		ibr_task0y6m ibr_task1y ibr_task1y6m;
global schooltask		cbi_ta6y cbi_ta8y;
global schoolsociab		new_cbi_ho6y new_cbi_ho8y;
global ncog			earlysociab earlytask schoolsociab scholtask;
global ncog_labels		Early-sociability Early-task School-sociability School-task;

global earlyiq			iq2y iq3y iq4y iq5y;
global earlyse			ibr_sociab0y6m ibr_sociab1y ibr_sociab1y6m;
global home			home_abspun2y6m home_abspun1y6m home_abspun0y6m
				home_abspun4y6m home_abspun3y6m;
global ach			math6y read6y math8y read8y read12y math12y;
global skills			earlyse home earlyiq ach;
global skills_labels		Social-emotional Parenting IQ Achievement;

global income			si30y_inc_labor si30y_works_job si21y_inc_labor;
global education		years_30y si30y_univ_comp hs21y;

global health			si34y_drugs FRiskScore smoker si34y_obese 
				si34y_sev_obese si34y_hemoglobin 
				si34y_prehyper si34y_hyper;
global crime			totfel totmis;
global adult			income education health crime;
global adult_labels		Income Education Heatlh Crime;

global income			si30y_inc_labor;
global years_30y		years_30y;
global crime			crime;
global si34y_bmi		si34y_bmi;
global adultsimp		si30y_inc_labor years_30y si34y_bmi crime;
global adultsimp_labels		Income Education Health Crime;

global varstofactor		$adultsimp;
global categories		adultsimp;

local numcats : word count $categories ;	// number of categories
local numvars : word count $varstofactor ; 	// number of factors

# delimit cr

// data
cd $scripts
cd abccare/genderdifferences
include abccare-npv

cd $data
merge m:1 id using append-abccare_iv 
keep if _merge == 3
drop _merge 

drop if R == 0 & RV == 1

tempfile npv
save   "`npv'", replace

// change some variables
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
egen new_pari_auth0y6m = rowtotal(pari_dpnd0y6m pari_scls0y6m pari_noaggr0y6m pari_isltd0y6m pari_supsex0y6m)
replace new_pari_auth0y6m=. if new_pari_auth0y6m==0
label var new_pari_auth0y6m "Appropriate sum of subscales for authority factor, 0y6m"
egen new_pari_hostl0y6m = rowtotal(pari_maritl0y6m pari_nohome0y6m pari_rage0y6m)
replace new_pari_hostl0y6m=. if new_pari_hostl0y6m==0
label var new_pari_hostl0y6m "Appropriate sum of subscales for hostility factor, 0y6m"
egen new_pari_demo0y6m = rowtotal(pari_verb0y6m pari_egal0y6m pari_comrde0y6m)
replace new_pari_demo0y6m=. if new_pari_demo0y6m==0
label var new_pari_demo0y6m "Appropriate sum of subscales for democratic factor, 0y6m"
*/
egen new_pari_auth1y6m = rowtotal(pari_dpnd1y6m pari_scls1y6m pari_noaggr1y6m pari_isltd1y6m pari_supsex1y6m)
replace new_pari_auth1y6m=. if new_pari_auth1y6m ==0
label var new_pari_auth1y6m "Appropriate sum of subscales for authority factor, 1y6m"
egen new_pari_hostl1y6m = rowtotal(pari_maritl1y6m pari_nohome1y6m pari_rage1y6m)
replace new_pari_hostl1y6m=. if new_pari_hostl1y6m==0
label var new_pari_hostl1y6m "Appropriate sum of subscales for hostility factor, 1y6m"
egen new_pari_demo1y6m = rowtotal(pari_verb1y6m pari_egal1y6m pari_comrde1y6m)
replace new_pari_demo1y6m=. if new_pari_demo1y6m==0
label var new_pari_demo1y6m "Appropriate sum of subscales for democratic factor, 1y6m"

foreach v in sped ret {
	gen never_`v' = ever_`v'
	recode never_`v' (1=0) (0=1)
}

// bootstrap
local j = 0
forvalues b1 = 1/$bootstraps {
	forvalues b2 = 1/$bootstraps {
	
	local j = `j' + 1 
	preserve
	
		if `b1' > 1 & `b2' > 1  {
			bsample
		}
		
		// create factors 
		foreach c in $varstofactor { 
		
			if "`c'" != "income" {
				qui keep if adraw == 0
			}
			else {
				qui keep if adraw == `b1'
			}
		
			local numx : word count ${`c'}
			if `numx' > 1 {
				qui factor  ${`c'} 
				qui predict `c'factor_tmp 
			}
			else {
				gen `c'factor_tmp = `c'
			}
			qui sum `c'factor_tmp 
			qui replace `c'factor_tmp = (`c'factor_tmp - r(mean))/r(sd) 
			xtile `c'factor = `c'factor_tmp, nquantiles($quantiles)
			qui drop `c'factor_tmp
			
			/*
			// standardized variables
			foreach v in ${`c'} {
				qui sum `v'
				qui gen `v'_tmp = (`v' - r(mean))/r(sd)
				drop `v'
				xtile `v' = `v'_tmp, nquantiles($quantiles)
				qui drop `v'_tmp
			}
			*/
		}
		
		// calculate means by gender
		foreach c in $categories {
			foreach v in ${`c'} {
				forvalues s = 0/1 {
					qui sum `v'factor if male == `s'
					matrix `v'`s'_`j' = r(mean)
				
					matrix `v'`s' = (nullmat(`v'`s') \ `v'`s'_`j')
					matrix colnames `v'`s' = `v'`s'
				}
			}
		}
	
	restore
	}
}

// bring to data
local mattoappend
local i = 0

forvalues s = 0/1 {
	foreach c in $categories {
		foreach v in ${`c'} {
		
			local i = `i' + 1
		
			if `i' < 2 * `numvars' {
				local mattoappend `mattoappend' `v'`s',
			}
			else {	
				local mattoappend `mattoappend' `v'`s'
			}
		}
	}
}
di "`mattoappend'"
mat allmeans = (`mattoappend')
clear
svmat allmeans, names(col)
qui gen b = _n

// inference and organize graph

local baroptions0 barwidth(0.2) bcol(white) blcol(black) lwidth(thick)
local baroptions1 barwidth(0.2) bcol(gs8) blcol(gs8) lwidth(thick)

foreach c in $categories {
	
	//local `c'graph
	local j = 0
	
	local numx : word count ${`c'}
	//local numx = `numx' + 1
	forvalues i = 1/`numx' {
		gen n`i'_0 = `i' - 0.125
		gen n`i'_1 = `i' + 0.125
	}
	
	local n = 0
	foreach l in ${`c'_labels} {
		local n = `n' + 1
		local `c'axis ``c'axis' `n' "`l'"
	}
	
	foreach v in ${`c'} {

		local j = `j' + 1
		
		forvalues s = 0/1 {
			local `c'graph ``c'graph' (bar m`v'`s' n`j'_`s', `baroptions`s'')
			local `c'graph ``c'graph' (rcap u`v'`s' l`v'`s' n`j'_`s', lcol(black))
			local `c'graph ``c'graph' (scatter m`v'`s' n`j'_`s' if ptwo`v' <= 0.1, mcol(black))
		
			// point estimate
			qui sum `v'`s' if b == 1
			qui gen point`v'`s' = r(mean)
		
			// empirical mean
			qui sum `v'`s' if b > 1
			qui gen m`v'`s' = r(mean)
		
			// standard errors
			qui sum `v'`s' if b > 1
			qui gen se`v'`s' = r(sd)
			qui gen u`v'`s' = m`v'`s' + se`v'`s'
			qui gen l`v'`s' = m`v'`s' - se`v'`s'
		}
	
		// male - female
		qui gen gd`v' = `v'1 - `v'0
	
		// point estimate of male - female
		qui gen gdpoint`v' = point`v'1 - point`v'0
	
		// empirical mean of male - female
		qui sum gd`v' if b > 1 & !missing(gd`v'`s')
		qui gen mgd`v' = r(mean)
		
		// demean
		qui gen dgd`v' = gd`v' - mgd`v' if b > 1
		
		// p-values
		qui gen dlower`v' = (dgd`v' < gdpoint`v') 		if !missing(dgd`v')
		qui gen dupper`v' = (dgd`v' > gdpoint`v') 		if !missing(dgd`v')
		qui gen dtwo`v'   = (abs(dgd`v') >= abs(gdpoint`v')) 	if !missing(dgd`v')
		
		foreach p in lower upper two {
			qui sum d`p'`v'
			qui gen p`p'`v' = r(mean)
		}		
	}

	// graph

	# delimit ;
		twoway 	``c'graph'
			,
		ylabel(0(3)18, angle(0) glcol(gs13))
		xlabel(``c'axis', labsize(vsmall))
		graphregion(color(white))
		legend(rows(1) order(1 4 2 3) size(small) label(1 "Female") label(4 "Male") label(2 "+/- s.e.") label(3 "p-value {&le} 0.10"))
		name(`c', replace)
		;
	# delimit cr
	//graph export "${output}/abccare-gdiff-`c'.eps", replace
	
	drop n?_0 n?_1
}
