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

// iq conditional on bayley mdi at 12 and 24 months 
global condition0 if male == 0
global condition1 if male == 1 
global condition2 if male != . 

matrix ddec0a = J(5,1,.)
matrix rownames ddec0a = 7 8 12 15 21
matrix ddec1a = ddec0a
matrix ddec2a = ddec0a

foreach b of numlist 1(1)100 {
	preserve
	bsample
	foreach sex in 0 1 2 {
		foreach num in 3 4 5 7 8 12 15 21 {
			xtile iq`num'decs`sex' = iq`num'y ${condition`sex'}, nq(20)
		}
	}

	foreach sex in 0 1 2 {
		summ iq5decs`sex' ${condition`sex'} & R == 0
		local decs5`sex'_cont = r(mean)
		
		summ iq5decs`sex' ${condition`sex'} & R == 1
		local decs5`sex'_treat = r(mean)
		
		matrix ddec`sex' = J(1,2,.)
		matrix colnames ddec`sex' = cont`b' treat`b' 

		foreach num in 7 8 12 15 21 {
			local numel
			
			
			summ iq`num'decs`sex' ${condition`sex'} & R == 0
			local  decs`num'`sex'_cont  = r(mean)
			local ddecs`num'`sex'_cont =  (`decs`num'`sex'_cont' -  `decs5`sex'_cont')/ `decs5`sex'_cont'
		
			summ iq`num'decs`sex' ${condition`sex'} & R == 1
			local  decs`num'`sex'_treat = r(mean)
			local ddecs`num'`sex'_treat =  (`decs`num'`sex'_treat' -  `decs5`sex'_treat')/ `decs5`sex'_treat'
		
			matrix ddec`num'`sex' = [`ddecs`num'`sex'_cont',`ddecs`num'`sex'_treat']
			matrix colnames ddec`num'`sex' = cont`b' treat`b'
			mat_rapp ddec`sex' : ddec`sex' ddec`num'`sex'
		
		}
		matrix ddec`sex'_`b' = ddec`sex'[2...,1...]
		matrix rownames ddec`sex'_`b' = 7 8 12 15 21 
		mat_capp ddec`sex'a : ddec`sex'a ddec`sex'_`b'
	}
	restore
}
matrix ddec0a = ddec0a[1...,2...]
matrix ddec1a = ddec1a[1...,2...]
matrix ddec2a = ddec2a[1...,2...]

foreach num of numlist 0 1 {
	preserve
	clear
	svmat ddec`num'a, names(col)
	
	egen treat   = rowmean(treat*)
	egen control = rowmean(cont*)
	
	egen treatse   = rowsd(treat*)
	egen controlse = rowsd(cont*)
	
	gen age = _n
	
	gen treatmax = treat + treatse
	gen treatmin = treat - treatse
	
	gen controlmax = control + controlse
	gen controlmin = control - controlse
	drop if age == 4
	
	#delimit
	twoway (lowess treat      age, /*msymbol(circle) mfcolor(gs0) msize(large) mlcolor(gs0) connect(l)*/ lwidth(medthick) lpattern(solid) lcolor(gs0))
	       (lowess    treatmax   age, lwidth(medium) lpattern(solid) lcolor(gs7))
	       (lowess    treatmin   age, lwidth(medium) lpattern(solid) lcolor(gs7))	       
	       (lowess control age ,   /*msymbol(square) msize(large) mfcolor (gs0) mlcolor(gs0) connect(l)*/ lwidth(medthick) lpattern(dash) lcolor(gs0))
	       (lowess controlmax age , lwidth(medium) lpattern(dash) lcolor(gs7))
	       (lowess controlmin age  , lwidth(medium) lpattern(dash) lcolor(gs7))	  
	        , 
			  legend(label(1 "Treatment") label(2 "+/- s.e.") label(4 "Control") 
			  		 label(5 "+/- s.e.") size(small) order(1 2 4 5) rows(2) cols(2))
			  xlabel(1 "7" 2 "8" 3 "12" 4 "15" 5 "21", grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
			  xtitle(Age) ytitle("", size(small))
			  graphregion(color(white)) plotregion(fcolor(white));
	#delimit cr
	graph export abccareiqranks_`num'.eps, replace 
	restore 
}
