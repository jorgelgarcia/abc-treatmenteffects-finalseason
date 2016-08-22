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

// iq conditional on bayley mdi at 12 and 24 months 
global condition0 if male == 0
global condition1 if male == 1 
global condition2 if male != . 

matrix ddec0a = J(7,1,.)
matrix rownames ddec0a = 3 5 7 8 12 15 21
matrix ddec1a = ddec0a
matrix ddec2a = ddec0a

foreach b of numlist 1(1)250 {
	preserve
	bsample
	
	foreach sex in 0 1 2 {
		foreach num in 3 4 5 7 8 12 15 21 {
			reg iq`num'y iq5y
			matrix b = e(b)
			matrix b = b[1,1]
			gen iq`num'y_anch_`sex' = iq`num'y*b[1,1]
		}
	}

	foreach sex in 0 1 2 {
		summ iq3y_anch_`sex' ${condition`sex'} & R == 0
		local decs3`sex'_cont = r(mean)
		
		summ iq3y_anch_`sex' ${condition`sex'} & R == 1
		local decs3`sex'_treat = r(mean)
		
		matrix ddec`sex' = J(1,2,.)
		matrix colnames ddec`sex' = cont`b' treat`b' 

		foreach num in 3 5 7 8 12 15 21 {
			
			summ iq`num'y_anch_`sex' ${condition`sex'} & R == 0
			local  decs`num'`sex'_cont  = r(mean)
			local ddecs`num'`sex'_cont =  (`decs`num'`sex'_cont' -  `decs3`sex'_cont')/ `decs3`sex'_cont'
		
			summ iq`num'y_anch_`sex' ${condition`sex'} & R == 1
			local  decs`num'`sex'_treat = r(mean)
			local ddecs`num'`sex'_treat =  (`decs`num'`sex'_treat' -  `decs3`sex'_treat')/ `decs3`sex'_treat'
		
			matrix ddec`num'`sex' = [`ddecs`num'`sex'_cont',`ddecs`num'`sex'_treat']
			matrix colnames ddec`num'`sex' = cont`b' treat`b'
			mat_rapp ddec`sex' : ddec`sex' ddec`num'`sex'
		
		}
		matrix ddec`sex'_`b' = ddec`sex'[2...,1...]
		matrix rownames ddec`sex'_`b' = 3 5 7 8 12 15 21 
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
	
	// p-values
	gen ptreat   = 2*(1 - normal(abs(treat/treatse)))
	gen pcontrol = 2*(1 - normal(abs(control/controlse)))
	
	
	#delimit
	twoway (line    treat   age, lwidth(medthick) lpattern(solid) lcolor(gs0))
	       (scatter treat   age if ptreat >  .10, msymbol(circle) msize(medium) mfcolor (none) mlcolor(gs0))
	       (scatter treat   age if ptreat <= .10, msymbol(circle) msize(medium) mfcolor (gs0) mlcolor(gs0))      
	       (line    control   age, lwidth(medthick) lpattern(dash) lcolor(gs0))
	       (scatter control   age if pcontrol >  .10, msymbol(circle) msize(medium) mfcolor (none) mlcolor(gs0))
	       (scatter control   age if pcontrol <= .10, msymbol(circle) msize(medium) mfcolor (gs0) mlcolor(gs0))   
	        , 
			  legend(label(1 "Treatment") label(4 "Control") label(2 "p-value > .10") 
			  		 label(3 "p-value {&le} .10") size(small) order(1 4 2 3) rows(2) cols(2))
			  xlabel(1 "3" 2 "5" 3 "7" 4 "8" 5 "12" 6 "15" 7 "21", grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
			  xtitle(Age) ytitle("", size(small))
			  graphregion(color(white)) plotregion(fcolor(white));
	#delimit cr
	graph export abccareiqranks_`num'.eps, replace 
	restore 
}
