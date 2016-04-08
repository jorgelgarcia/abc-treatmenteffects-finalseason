version 12.0
set more off
clear all
set matsize 11000
set maxvar  32000

/*
Project :       ABC, CARE Treatment Effects
Description:    this .do file compares ABC and CARE to PSID
*This version:  April 8, 2015
*This .do file: Jorge L. Garcia
*/

// set environment variables (server)
global erc: env erc
global projects: env projects
global klmshare:  env klmshare
global klmmexico: env klmMexico
global googledrive: env googledrive

// set general locations
// do files
global scripts    = "$projects/abc-treatmenteffects-finalseason/scripts/"
// ready data
global datapsid    = "$klmshare/Data_Central/data-repos/psid/base/"
global dataabccare = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
// output
global output     = "$projects/abc-treatmenteffects-finalseason/output/"

// ABC
// open psid-abc match
cd $datapsid
use psid-base.dta, clear

// grab relevant cohort at 1977
keep if inlist(age1977,0,1,2,3,4,5,6)

// keep relevant outcomes and flags for abc-comparable sample 
keep id cweight2005 age1977 f_home* m_age* m_edu* fam_inc* inc_labor* edu* cig* bmi* race* male 

gen     year0 = .
replace year0 = 1977 if age1977 == 1 //
replace year0 = 1976 if age1977 == 2 //4th cohort
replace year0 = 1975 if age1977 == 3 //3rd cohort
replace year0 = 1974 if age1977 == 4 //2nd cohort
replace year0 = 1973 if age1977 == 5 //1st cohort
replace year0 = 1972 if age1977 == 6 

gen     year31 = .
replace year31 = 2007 if age1977 == 1 //
replace year31 = 2006 if age1977 == 2 //4th cohort
replace year31 = 2005 if age1977 == 3 //3rd cohort
replace year31 = 2004 if age1977 == 4 //2nd cohort
replace year31 = 2003 if age1977 == 5 //1st cohort
replace year31 = 2002 if age1977 == 6 

// arrange baseline outcomes
foreach y in f_home m_age m_edu fam_inc {
	gen `y'0 = .
	replace `y'0 = `y'1973 if (year0 == 1973 | year0 == 1972)
	replace `y'0 = `y'1975 if (year0 == 1975 | year0 == 1974)
	replace `y'0 = `y'1977 if (year0 == 1977 | year0 == 1976)
}
la var fam_inc0 "Labor income of parents (2014$)"
rename fam_inc0 p_inc0

gen black =( race == 2 ) if race != .

// append psid-abc 
gen abcdata = 0
keep id abcdata f_home0 m_age0 m_edu0 p_inc0 cweight2005 black male
tempfile   data_psid
save     "`data_psid'", replace

cd $dataabccare
use append-abccare_iv.dta, clear

keep if abc == 1
gen abcdata = 1
rename m_ed0y m_edu0
rename f_home0y f_home0
rename m_age0y m_age0 
rename p_inc0y p_inc0 
keep id f_home0 m_edu0 m_age0 m_edu0 p_inc0 treat male abcdata
append using "`data_psid'"

// save abccare_file
tempfile abc_psid
save     "`abc_psid'", replace

// CARE
// open psid-abc match
cd $datapsid
use psid-base.dta, clear

// grab relevant cohort at 1978-1979
keep if inlist(age1978,0,1,2,3)

// keep relevant outcomes and flags for abc-comparable sample 
keep id cweight2005 age1978 f_home* m_age* m_edu* fam_inc* race* male

gen     year0 = .
replace year0 = 1978 if age1978 == 1 //
replace year0 = 1979 if age1978 == 2 //4th cohort
replace year0 = 1980 if age1978 == 3 //3rd cohort
replace year0 = 1981 if age1978 == 4 //2nd cohort

gen     year31 = .
replace year31 = 2008 if age1978 == 1 //
replace year31 = 2009 if age1978 == 2 //4th cohort
replace year31 = 2010 if age1978 == 3 //3rd cohort
replace year31 = 2011 if age1978 == 4 //2nd cohort

// arrange baseline outcomes
foreach y in f_home m_age m_edu fam_inc {
	gen `y'0 = .
	replace `y'0 = `y'1979 if (year0 == 1978 | year0 == 1979)
	replace `y'0 = `y'1981 if (year0 == 1980 | year0 == 1981)
}
la var fam_inc0 "Labor income of parents (2014$)"
rename fam_inc0 p_inc0
 
gen black =( race == 2 ) if race != .

// append psid-abc 
gen caredata = 0
keep id caredata f_home0 m_age0 m_edu0 p_inc0 cweight2005 black male
tempfile   data_psid
save     "`data_psid'", replace

cd $dataabccare
use append-abccare_iv.dta, clear

drop if abc == 1
rename m_ed0y m_edu0
rename f_home0y f_home0
rename m_age0y m_age0
rename p_inc0y p_inc0
keep id f_home0 m_edu0 m_age0 p_inc0 treat male
append using "`data_psid'"
replace caredata = 1 if caredata == .

// save abccare_file
tempfile   care_psid
save     "`care_psid'", replace
append using "`abc_psid'"


// plot analysis
cd $output
// medians or means in matrices
global poolcondition 
global   malecondition & male == 1
global femalecondition & male == 0

global f_home0_ylabel 0[.2].8
global m_age0_ylabel  16[4]28
global m_edu0_ylabel  8[2]12
global p_inc0_ylabel  0[10]60
 
foreach gender in pool male female {
	matrix allvars`gender' = J(4,1,.)
	matrix rownames allvars`gender' = c1 c2 c3 c4
	
	// means
	foreach var of varlist f_home0 /*m_age0 m_edu0 p_inc0*/ {
		summ `var' [aw = cweight2005] if (abcdata == 0 | caredata == 0) ${`gender'condition}, det
		local `var'`gender'psid  = r(mean)
		summ `var'  if (abcdata == 0 | caredata == 0) ${`gender'condition}
		local `var'`gender'psidN = r(N)
		
		summ `var' [aw = cweight2005] if (abcdata == 0 | caredata == 0) & black == 1 ${`gender'condition}, det
		local `var'`gender'psidblack = r(mean)
		summ `var'  if (abcdata == 0 | caredata == 0) & black == 1 ${`gender'condition}
		local `var'`gender'psidblackN = r(N)
		
		summ `var' if abcdata == 1 ${`gender'condition}, det
		local `var'`gender'abc  = r(mean)
		local `var'`gender'abcN = r(N)
		
		summ `var' if caredata == 1 ${`gender'condition}, det
		local `var'`gender'care  = r(mean)
		local `var'`gender'careN = r(N)
		
		matrix `var'`gender' = [``var'`gender'psid',``var'`gender'psidblack',``var'`gender'abc',``var'`gender'care']'
		matrix rownames `var'`gender' = c1 c2 c3 c4
		matrix colnames `var'`gender' = `var'`gender'
		
		mat_capp allvars`gender' : allvars`gender' `var'`gender'
	}
	matrix allvars`gender' = allvars`gender'[1...,2...]
	
	preserve
	clear
	svmat allvars`gender', names(col)
	gen category = _n*2 - 1
	
	foreach var in f_home0 /*m_age0 m_edu0 p_inc0*/ {
	#delimit
	twoway 	(bar `var'`gender' category, lwidth(medium) lcolor(gs0) fcolor(none)),
		xlabel(1 "National, All (N = ``var'`gender'psidN')" 3 "National, Black (N = ``var'`gender'psidblackN')" 5 "ABC (N = ``var'`gender'abcN')"
		       7 "CARE (N = ``var'`gender'careN')", grid glcolor(gs14) angle(55) labsize(medsmall)) 
		     ylabel(${`var'_ylabel}, angle(h) glcolor(gs14))
		xtitle("") ytitle(Mean, size(small))
		graphregion(color(white)) plotregion(fcolor(white));
	#delimit cr
	graph export abccarepsid_`var'`gender'.eps, replace
	}
	restore 
}
