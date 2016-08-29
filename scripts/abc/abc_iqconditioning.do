version 12.0
set more off
clear all
set matsize 11000

/*
Project :       ABC
Description:    plot estimates conditional on IQ
*This version:  April 18, 2016
*This .do file: Jorge L. Garcia
*This project : All except Seong, B. and CC. 
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

// open merged data
cd $dataabccare
use append-abccare_iv.dta, clear
cd $output

// abc sample
drop if random == 3

/*
// bayley mdi by cohort
tab cohort, gen(cohort_)

foreach num of numlist 1(1)4 { 
	gen treat_cohort_`num' = treat*cohort_`num'
}

foreach var of varlist mdi0y6m mdi1y {
	reg `var' treat_cohort_1 treat_cohort_2 treat_cohort_3 treat_cohort_4 cohort_1 cohort_2 cohort_3
	est sto `var'_est
}

cd $output
outreg2 [mdi0y6m_est mdi1y_est] using abc_cohorts, replace tex dec(3) par(se) r2 nocons nonotes /// 
				keep(treat_cohort_1 treat_cohort_2 treat_cohort_3 treat_cohort_4)

// iq conditional on bayley mdi at 12 and 24 months 
global condition0 if male == 0
global condition1 if male == 1 
global condition2
*/ 

rename mdi1y iq1y

foreach sex in 0 1 {
	matrix iq_`sex' = J(1,4,.)
	matrix colnames iq_`sex' = itt seitt ittc seittc
	foreach age in 1 2 3 4 5 7 8 12 15 21 { 
		reg iq`age'y treat ${condition`sex'}
		matrix bitt_`sex'_`age' = e(b)
		matrix bitt_`sex'_`age' = bitt_`sex'_`age'[1,1]
		matrix Vitt_`sex'_`age' = e(V)
		matrix Vitt_`sex'_`age' = sqrt(Vitt_`sex'_`age'[1,1])
		
		reg iq`age'y treat iq3y ${condition`sex'}
		matrix bittc_`sex'_`age' = e(b)
		matrix bittc_`sex'_`age' = bittc_`sex'_`age'[1,1]
		matrix Vittc_`sex'_`age' = e(V)
		matrix Vittc_`sex'_`age' = sqrt(Vittc_`sex'_`age'[1,1])
	    
	    matrix iq_`sex'_`age' = [bitt_`sex'_`age',Vitt_`sex'_`age',bittc_`sex'_`age',Vittc_`sex'_`age']
		matrix colnames iq_`sex'_`age' = itt seitt ittc seittc
		mat_rapp iq_`sex' : iq_`sex' iq_`sex'_`age'
	}
	matrix iq_`sex' = iq_`sex'[2...,1...]
	
	preserve 
	clear 
	svmat iq_`sex', names(col)
	
	foreach var in itt ittc {
		gen `var'mse = `var' - se`var' 
		gen `var'pse = `var' + se`var'
	}
	
	gen age = _n
	
	#delimit
	twoway (scatter itt      age, msymbol(circle) mfcolor(gs0) msize(large) mlcolor(gs0) connect(l) lwidth(medthick) lpattern(solid) lcolor(gs0))
		   (line ittmse  age, lwidth(medium) lpattern(solid) lcolor(gs7))
		   (line ittpse  age, lwidth(medium) lpattern(solid) lcolor(gs7))	       	  
	        , 
			  legend(label(1 "Mean Treatment - Mean Control") label(2 "+/- s.e.") size(small) order(1 2) rows(1))
			  xlabel(1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "7" 7 "8" 8 "12" 9 "15" 10 "21", grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
			  xtitle(Age) ytitle("", size(small))
			  graphregion(color(white)) plotregion(fcolor(white));
	#delimit cr
	graph export abc_iqfixing_`sex'.eps, replace 
	restore 
}	
