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
global scripts      = "$projects/abc-treatmenteffects-finalseason/scripts/"
// ready data
global datatreatp   = "$klmmexico/abccare/treatmenteffects/hhsib0y_restricted_20160923"
global dataabccare  = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
// output
global output       = "$projects/abc-treatmenteffects-finalseason/output/"

set seed 0
global no_siblingsuff  sib0
global yes_siblingsuff sib1
global all_siblingsuff sib10

local sexnum = 0
foreach group in all_sibling no_sibling yes_sibling {
	local sexnum = `sexnum' + 1
	cd $datatreatp
	cd "`group'/itt"
	foreach sex in female male pooled {
		
		insheet using itt_`sex'_P10_${`group'suff}.csv, clear
		sort draw ddraw rowname itt_noctrl 
		keep draw ddraw rowname itt_noctrl
		
		gen varind =.
		replace varind = 1  if rowname == "m_work1y6m"
		replace varind = 5  if rowname == "m_work21y"  
		replace varind = 2  if rowname == "m_work2y6m" 
		replace varind = 3  if rowname == "m_work3y6m" 
		replace varind = 4  if rowname == "m_work4y6m" 
		replace varind = 11 if rowname == "p_inc12y"
		replace varind = 12 if rowname == "p_inc15y"
		replace varind = 6  if rowname == "p_inc1y6m" 
		replace varind = 13 if rowname == "p_inc21y"
		replace varind = 7  if rowname == "p_inc2y6m"
		replace varind = 8  if rowname == "p_inc3y6m"
		replace varind = 9  if rowname == "p_inc4y6m"
		replace varind = 10 if rowname == "p_inc8y"
		replace varind = 14 if rowname == "ip_p_inc_sum"
		
		capture drop if  itt_noctrl == "NA"
		destring itt_noctrl, replace
		summ itt_noctrl
		
		gen itt_noctrlre = itt_noctrl
		foreach num of numlist 1(1)14 {
			summ itt_noctrl if draw == 0 & ddraw == 0 & varind == `num'
			local est = r(mean)
			summ    itt_noctrl                                     if varind == `num'
			gen     itt_noctrl_mean`num' = r(mean)                 if varind == `num'
			replace itt_noctrl = itt_noctrl - itt_noctrl_mean`num' if varind == `num'
			
			gen     itt_noctrl_ind`num' = 1 if varind == `num'
			replace itt_noctrl_ind`num' = 0 if varind == `num' & (`est' > itt_noctrl)
			
			summ itt_noctrl_ind`num'
			gen itt_noctrl_p`num' = r(mean) if varind == `num'
		}
		
		aorder
		egen itt_noctrl_p = rowtotal(itt_noctrl_p1-itt_noctrl_p14), missing
		keep if draw == 0 & ddraw == 0
		gen  sexnum = `sexnum'
		sort varind
		order itt_noctrlre itt_noctrl_p varind sexnum
		keep itt_noctrlre itt_noctrl_p varind sexnum
		rename itt_noctrlre itt_noctrl
		mkmat *, matrix(`group'_`sex')
	}
}


cd $output
foreach sex in female male pooled {
	matrix allest`sex'          = [no_sibling_`sex' \ yes_sibling_`sex' \ all_sibling_`sex']
	matrix colnames allest`sex' = itt ittp varind sexnum
 	clear
	svmat allest`sex', names(col)
	sort varind sexnum
	replace varind = varind + .25 if sexnum == 2
	replace varind = varind + .5  if sexnum == 3
	replace itt = itt/1000
	
	/*
	#delimit
	twoway (bar itt varind if sexnum == 1 & varind >= 6 & varind <= 13.50, color(gs8) barwidth(.3))
	       (bar itt varind if sexnum == 2 & varind >= 6 & varind <= 13.50, color(gs4) barwidth(.3))
	       (bar itt varind if sexnum == 3 & varind >= 6 & varind <= 13.50, fcolor(white) lcolor(gs0) lwidth(medthick) barwidth(.3))
	      
	       (scatter itt varind if ittp <= .10 & varind >= 6 & varind <= 13.50, msymbol(circle) mlwidth(medthick) mlcolor(black) mfcolor(black) msize(small))
		, 
		legend(cols(3) order(1 "No Siblings" 2 "{&ge} Siblings" 3 "All" 4 "p-value {&le} .10") size(vsmall))
			  xlabel(6.25 "2" 7.25 "3" 8.25 "4" 9.25 "5" 10.25 "8" 11.25 "12" 12.25 "15" 13.25 "21", angle(45) noticks grid glcolor(gs14) labsize(small)) 
			  ylabel(, angle(h) glcolor(gs14))
			  xtitle(Age,) 
			  ytitle("Parental Income (1000s of 2014 USD)")
			  graphregion(color(white)) plotregion(fcolor(white));
	#delimit cr 
	graph export abccare_pincombyage`sex'.eps, replace
	*/

	keep if varind >= 14
	#delimit
	twoway (bar itt varind if sexnum == 1 & varind <= 14.25, color(gs8) barwidth(.22))
	       (bar itt varind if sexnum == 2 & varind <= 14.25, color(gs4) barwidth(.22))
	       (scatter itt varind if ittp <= .10 & varind <= 14.25, msymbol(circle) mlwidth(medthick) mlcolor(black) mfcolor(black) msize(large))
		, 
		legend(cols(3) order(1 "No Siblings at Baseline" 2 "> 0 Siblings at Baseline" 3 "p-value {&le} .10") size(small))
			  xlabel(14 " " 14.25 " ", angle(45) noticks grid glcolor(gs14) labsize(small)) 
			  ylabel(0[10]30, angle(h) glcolor(gs14))
			  xtitle(" ",) 
			  ytitle("Treatment Effect on Parental Income (1000s of 2014 USD)", size(small))
			  graphregion(color(white)) plotregion(fcolor(white));
	#delimit cr
	graph export abccare_pincomesum_s`sex'.eps, replace
}
