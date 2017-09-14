/*
Project: 	Treatment effects
Date:		September 13, 2017

This file:	Graph differences in proportions: ABC/CARE, IHDP, Perry
*/

clear all
set more off
set maxvar 30000
set matsize 11000

// parameters
set seed 1
global bootstraps 	1000
global quantiles 	30

// macros
global projects		: env projects
global klmshare		: env klmshare
global klmmexico	: env klmMexico

// filepaths
global scripts    	= "$projects/abccare-cba/scripts/"
global output      	= "$projects/abccare-cba/output/"

// data

cd $output

import excel using "abccare-perry-proportions-manual.xlsx", firstrow clear

labmask order, values(cat)
gen order2 = order + 0.225
gen order3 = order2 + 0.225
gen ref0 = 0

/*
# delimit ;
graph bar abc0 perry0 abc1 perry1 space, over(order, label(labsize(vsmall) angle(30)))
	graphregion(color(white)) 
	bar(1, bcol(black)) bar(2, bcol(gs10)) 
	bar(3, blcol(black) blwidth(thin) bcol(none))
	ytitle("Proportion of Outcomes, Males > Females", size(small)) 
	legend(order(1 2 3 4) label(1 "ABC/CARE, Control") label(2 "Perry, Control") 
	label(3 "ABC/CARE, Treatment") label(4 "Perry, Treatment") size(small))
;
# delimit cr

graph export "abccare-perry-proportions.eps", replace
*/

# delimit ;
twoway (rcapsym abcdiff ref0 order, msymb(S) lcol(black) lwidth(thick) mcol(black))
		(rcapsym perrydiff ref0 order2, lcol(gs8) lwidth(thick) mcol(gs8))
		(rcapsym ihdpdiff ref0 order3 if ihdpdiff != ., lwidth(thick) mcol(green) lcol(green) msymb(T)),
		graphregion(color(white))
		legend(rows(1) label(1 ABC/CARE) label(2 Perry) label(3 IHDP))
		yline(0, lcol(gs9))
		xlabel(1(1)11, valuelabels labsize(vsmall) angle(20))
		ylabel(, angle(0) glcol(gs14))
		ytitle("Difference in Proportion of Outcomes Male > Female", size(small));
# delimit cr

cd $output
graph export "abccare-perry-ihdp-diff.eps", replace
