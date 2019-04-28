
set more off
clear all
set matsize 11000

/*
Project    :  ABC CBA

Description:  this .do file describes education variables at age 30 in ABC

Basics:       
		
This version: 07/09/2015

This .do file: Jorge Luis Garcia
This project : CEHD
*/

// set environment variables
global erc: env erc
global projects: env projects
global klmshare: env klmshare
global klmmexico: env klmMexico
global googledrive: env googledrive

// declare addresses
global dofiles = "$klmmexico/abc-cba/analysis/cba/allcomponents"
// abc-data
global data    = "$klmmexico/abc-cba/analysis/cba/rslt/"
// output
global output  = "$klmmexico/abc-cba/abc-cba-draft/MainOutput/misc"

// 
cd $data
set obs 86
gen age = _n - 1
tempfile age
save "`age'", replace

# delimit 
foreach flow in parent_inc cc edu crimepublic crimeprivate labor_inc program qaly transfer_inc 
                oopmd mcare caidmd miscmd diclaim ssiclaim ssclaim oopmd_pre30 caidmd_pre30 miscmd_pre30 {;

# delimit cr

preserve
insheet using flow_`flow'_m.csv, clear
collapse *
drop draw
gen id = 1
reshape long c, i(id) j(age) 
rename c `flow'_m
replace `flow'_m = 0 if `flow'_m == .
replace `flow'_m = `flow'_m / (1.03 ^ age)

tempfile `flow'_m
save "``flow'_m'", replace
bysort id: gen `flow'_m_cum = sum(`flow'_m)

drop id
save "``flow'_m'", replace
restore

preserve
insheet using flow_`flow'_f.csv, clear
collapse *
drop draw
gen id = 1
reshape long c, i(id) j(age) 
rename c `flow'_f 

replace `flow'_f = 0 if `flow'_f == .
replace `flow'_f = `flow'_f / (1.03 ^ age)
bysort id: gen `flow'_f_cum = sum(`flow'_f)

drop id
tempfile `flow'_f 
save "``flow'_f'", replace
restore
}


clear
set obs 86
gen age = _n - 1

# delimit 
foreach flow in parent_inc cc edu crimepublic crimeprivate labor_inc program qaly transfer_inc 
                oopmd mcare caidmd miscmd diclaim ssiclaim ssclaim oopmd_pre30 caidmd_pre30 miscmd_pre30 {;
# delimit cr

	merge 1:1 age using "``flow'_m'"
	drop if _merge == 2
	drop _merge
	
	merge 1:1 age using "``flow'_f'"
	drop if _merge == 2
	drop _merge
}

drop qaly_m_cum qaly_f_cum
replace qaly_f = 150000*qaly_f
replace qaly_m = 150000*qaly_m
gen id = 1
bysort id : gen qaly_f_cum = sum(qaly_f)
bysort id : gen qaly_m_cum = sum(qaly_m)

drop ssiclaim_m_cum ssiclaim_f_cum
replace ssiclaim_f  = ssiclaim_f * -0.5 * 1.02 * 12 * 901.5 // DWL * Inflation * months * claim per month
replace ssiclaim_m  = ssiclaim_m * -0.5 * 1.02 * 12 * 901.5 // DWL * Inflation * months * claim per month
bysort id: gen ssiclaim_f_cum = sum(ssiclaim_f)
bysort id: gen ssiclaim_m_cum = sum(ssiclaim_m)

drop ssclaim_m_cum ssclaim_f_cum
replace ssclaim_f = ssclaim_m * -0.5 * 1.02 * 12 * 1228 // DWL * Inflation * months * claim per month
replace ssclaim_m = ssclaim_m * -0.5 * 1.02 * 12 * 1228 // DWL * Inflation * months * claim per month
bysort id: gen ssclaim_f_cum = sum(ssclaim_f)
bysort id: gen ssclaim_m_cum = sum(ssclaim_m)

preserve
insheet using di_claim.csv, names clear
levelsof age, local(ages)
foreach a in `ages' {
	levelsof m if age == `a', local(m`a')
	levelsof f if age == `a', local(f`a')
}
restore

drop diclaim_m_cum diclaim_f_cum
levelsof age, local(ages)
foreach a in `ages' {
	if "`m`a''" != "" replace diclaim_m = diclaim_m * -0.5 * `m`a'' if age==`a'
	if "`f`a''" != "" replace diclaim_f = diclaim_f * -0.5 * `f`a'' if age==`a'
}
bysort id: gen diclaim_f_cum = sum(diclaim_f)
bysort id: gen diclaim_m_cum = sum(diclaim_m)


foreach var of varlist transfer_inc* {
	replace `var' = -.5*`var'
}

foreach var of varlist crimepublic* program* mcare* caidmd* {
	replace `var' = -1.5*`var'
}

foreach var of varlist edu* {
	replace `var' = -1.5 * `var' if age <= 18 
	replace `var' = -1 * `var' if age > 18 
}

foreach var of varlist oopmd* miscmd* cc* crimeprivate* {
	replace `var' = -`var'
}


foreach var of varlist * { 
	replace `var' = `var'/100000
}

replace age = age*100000

cd $output

foreach sex in f m {
	gen totmd_`sex'_cum  = mcare_`sex'_cum + oopmd_`sex'_cum + caidmd_`sex'_cum + miscmd_`sex'_cum 
	gen crime_`sex'_cum  = crimepublic_`sex'_cum + crimeprivate_`sex'_cum 
	gen transfer_`sex'_cum  = transfer_inc_`sex'_cum + diclaim_`sex'_cum + ssiclaim_`sex'_cum + ssclaim_`sex'_cum
	
	gen totmdqaly_`sex'_cum = totmd_`sex'_cum + qaly_`sex'_cum
	replace totmdqaly_`sex'_cum =  oopmd_pre30_`sex'_cum + caidmd_pre30_`sex'_cum + miscmd_pre30_`sex'_cum if age<30
	
	

	# delimit
	twoway 
		(lowess  totmdqaly_`sex'_cum    age if age >= 8, lwidth(vthick) color(gs0))
	       (lowess  crime_`sex'_cum        age if age >= 25 & age <= 50, lwidth(vthick) color(gs8))
		(scatter program_`sex'_cum      age if age <= 5,  msymbol(circle)    color(gs0))
		(scatter parent_inc_`sex'_cum   age if age <= 15,         msymbol(circle)  mfcolor(white) mlcolor(gs0)) 
	      
	       (scatter edu_`sex'_cum          age if age <= 30, msymbol(square)    mfcolor(white) mlcolor(gs0))
	       (scatter labor_inc_`sex'_cum    age if age >= 21 & age <= 65, msize(large) msymbol("x") color(gs0))

	       
		, 
	legend(	label(1 Medical Costs + QALYs) size(small)
		label(2 Crime) 
		label(3 Program) 
		label(4 Parental Income) 
		label(5 Education) 
		label(6 Labor Income) 
	      
	        cols(3) rows(3))
		xlabel(, nogrid glcolor(gs14)) ylabel(, nogrid angle(h) glcolor(gs14))
		xtitle(Age) ytitle("Accumulated Net Benefit (100,000 USD 2014)" , size(small))
		 graphregion(color(white)) plotregion(fcolor(white));
	# delimit cr 
	graph export accumulatedcosts_`sex'.eps, replace
}

