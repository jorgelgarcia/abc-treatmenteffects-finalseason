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
global scripts     = "$projects/abc-treatmenteffects-finalseason/scripts/"
// ready data
global datapsid    = "$klmshare/Data_Central/data-repos/psid/base/"
global dataabccare = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
// output
global output      = "$projects/abc-treatmenteffects-finalseason/output/"

// open merged data
cd $dataabccare
use append-abccare_iv.dta, clear
cd $output

// abc sample
drop if random == 3
rename mdi1y iq1y

// iq conditional on bayley mdi at 12 and 24 months 
global condition0 if male == 0
global condition1 if male == 1 
global condition2 if male != . 

matrix ddec0a = J(9,1,.)
matrix rownames ddec0a = 1 2 3 5 7 8 12 15 21
matrix ddec1a = ddec0a
matrix ddec2a = ddec0a


	
foreach sex in 0 1 2 {
	foreach num in 1 2 3 4 5 7 8 12 15 21 {
		reg iq5y iq`num'y ${condition`sex'}
		matrix b = e(b)
		matrix b = b[1,1]
		gen iq`num'y_anch_`sex' = iq`num'y*b[1,1] ${condition`sex'}
		xtile iq`num'y_anchg_`sex' = iq`num'y_anch_`sex', nq(20)
	}
}

foreach sex in 0 1 2 {
	summ iq3y_anchg_`sex' ${condition`sex'} & R == 0
	local decs3`sex'_cont = r(mean)
	
	summ iq3y_anchg_`sex' ${condition`sex'} & R == 1
	local decs3`sex'_treat = r(mean)
	
	matrix ddec`sex' = J(1,2,.)
	matrix colnames ddec`sex' = cont`b' treat`b' 

	foreach num in 1 2 3 5 7 8 12 15 21 {
			
		summ iq`num'y_anchg_`sex' ${condition`sex'} & R == 0
		local  decs`num'`sex'_cont  = r(mean)
		local ddecs`num'`sex'_cont =  (`decs`num'`sex'_cont' -  `decs3`sex'_cont')/ `decs3`sex'_cont'
		
		summ iq`num'y_anchg_`sex' ${condition`sex'} & R == 1
		local  decs`num'`sex'_treat = r(mean)
		local ddecs`num'`sex'_treat =  (`decs`num'`sex'_treat' -  `decs3`sex'_treat')/ `decs3`sex'_treat'
		
		matrix ddec`num'`sex' = [`ddecs`num'`sex'_cont',`ddecs`num'`sex'_treat']
		matrix colnames ddec`num'`sex' = cont`b' treat`b'
		mat_rapp ddec`sex' : ddec`sex' ddec`num'`sex'
		
	}

}
matrix ddec0 = ddec0[2...,1...]
matrix ddec1 = ddec1[2...,1...]
matrix ddec2 = ddec2[2...,1...]

foreach num of numlist 0 1 {
	preserve
	clear
	svmat ddec`num', names(col)
	
	gen age = _n
	drop if age == 8 | age == 7
	
	#delimit
	twoway (line treat   age, lwidth(medthick) lpattern(solid) lcolor(gs0))
	       //(lowess treatmax   age, lwidth(medthick) lpattern(dash) lcolor(gs0))
	       //(lowess treatmin   age, lwidth(medthick) lpattern(dash) lcolor(gs0))    
	       (line cont   age, lwidth(medthick) lpattern(solid) lcolor(gs8))
	       //(lowess controlmax   age, lwidth(medthick) lpattern(dash) lcolor(gs0))
	       //(lowess controlmin   age, lwidth(medthick) lpattern(dash) lcolor(gs0))
	        , 
			  legend(label(1 "Treatment") label(2 "Control") size(small) order(1 2) rows(1))
			  xlabel(1 "1" 2 "2" 3 "3" 4 "5" 5 "7" 6 "8" 7 "12" 8 "15" 9 "21", grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
			  xtitle(Age) ytitle("", size(small))
			  graphregion(color(white)) plotregion(fcolor(white));
	#delimit cr
	graph export abccareiqranks_`num'.eps, replace 
	restore 
}
