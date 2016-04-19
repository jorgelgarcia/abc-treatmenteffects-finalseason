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

// preparation preamble
keep if abc == 1

cd $output
foreach sex in 0 1 {
	matrix iq_`sex' = J(1,4,.)
	matrix colnames iq_`sex' = itt seitt ittc seittc
	foreach age in 3 4 5 7 8 12 15 21 { 
		reg iq`age'y treat if male == `sex'
		matrix bitt_`sex'_`age' = e(b)
		matrix bitt_`sex'_`age' = bitt_`sex'_`age'[1,1]
		matrix Vitt_`sex'_`age' = e(V)
		matrix Vitt_`sex'_`age' = sqrt(Vitt_`sex'_`age'[1,1])
		
		reg iq`age'y treat mdi1y mdi0y6m if male == `sex'
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
	twoway (scatter itt    age, msymbol(circle) mfcolor(gs0) msize(large) mlcolor(gs0) connect(l) lwidth(medthick) lpattern(solid) lcolor(gs0))
		   (line ittmse age, lwidth(medium) lpattern(solid) lcolor(gs7))
		   (line ittpse age, lwidth(medium) lpattern(solid) lcolor(gs7))	       
		   (scatter ittc    age if age > 1, msymbol(square) msize(large) mfcolor (gs0) mlcolor(gs0) connect(l) lwidth(medthick) lpattern(solid) lcolor(gs0))
		   (line ittcmse age if age > 1, lwidth(medium) lpattern(dash) lcolor(gs7))
		   (line ittcpse age if age > 1, lwidth(medium) lpattern(dash) lcolor(gs7))	  
	        , 
			  legend(label(1 "Mean Treatment - Mean Control") label(2 "+/- s.e.") label(4 "Mean Treatment - Mean Control, Controlling for IQ at Age 3") 
			  		 label(5 "+/- s.e.") size(small) order(1 2 4 5) rows(2) cols(2))
			  xlabel(1 "3" 2 "4" 3 "5" 4 "7" 5 "8" 6 "12" 7 "15" 8 "21", grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
			  xtitle(Age) ytitle("", size(small))
			  graphregion(color(white)) plotregion(fcolor(white));
	#delimit cr
	graph export iq3fixing_`sex'.eps, replace 
	restore 
}	
