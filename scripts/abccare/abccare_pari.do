version 12.0
set more off
clear all
set matsize 11000
set maxvar  32000

/*
Project :       CARE AND ABC
Description:    this .do file plots the PARI for ABC
*This version:  January 21, 2015
*This .do file: Jorge L. Garcia
*This project : HRI 
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

global  pari_auth_label "Parent is Authoritarian to Child" 
global  pari_demo_label "Parent-Child Democratic Relationship"

keep if program == "abc"

cd $output
foreach var of varlist pari_auth pari_demo {
		foreach num of numlist 0 1 {
			summ `var' if male == `num'
			replace `var' = (`var' - r(mean)/r(sd)) if male == `num'
			reg `var' treat if male == `num'
			matrix  b`num'  = e(b)
			local   b`num'  = round(b`num'[1,1],.0001)
			matrix  V`num'  = e(V)
			local  se`num'  = sqrt(V`num'[1,1])
			local   p`num'  = round((1 - normal(abs(`b`num''/`se`num''))),.0001)
		
		#delimit
		twoway (kdensity `var' if R == 0 & male == `num', lwidth(medthick) lpattern(solid) lcolor(dkorange))
		       (kdensity `var' if R == 1 & male == `num', lwidth(medthick) lpattern(solid) lcolor(emerald))
			, 
				  legend(label(1 Control) label(2 Treatment))
				  xlabel(, grid glcolor(gs14)) ylabel(, angle(h) glcolor(gs14))
				  xtitle(${`var'_label}) ytitle(Density)
				  graphregion(color(white)) plotregion(fcolor(white))
		note(Treatment Effect: `b`num'' (p-value = `p`num'')., size(vsmall) );
		#delimit cr 
		graph export abccre_pari_`var'_`num'.eps, replace
	}
}
