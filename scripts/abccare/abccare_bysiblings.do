version 12.0
set more off
clear all
set matsize 11000

/* 
Project: 			ABC and CARE CBA
This file:			Compare TE on observed parental income by # of siblings
Author:				Anna Ziff
Original date:		September 27, 2016
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
global datatreatp   = "$klmmexico/abccare/treatmenteffects/hhsib0y_restricted_20160926"
global dataabccare  = "$klmshare/Data_Central/Abecedarian/data/ABC-CARE/extensions/cba-iv/"
// output
global output       = "$projects/abc-treatmenteffects-finalseason/output/"

set seed 0
global no_siblingsuff  sib0
global yes_siblingsuff sib1
global all_siblingsuff sib10

local sexnum = 0
foreach group in no_sibling yes_sibling all_sibling {
	local sexnum = `sexnum' + 1
	cd $datatreatp
	cd "`group'/itt"
	foreach sex in female male pooled {
		
		insheet using itt_`sex'_P10_${`group'suff}.csv, clear
		sort draw ddraw rowname itt_noctrl 
		keep draw ddraw rowname itt_noctrl
		keep if rowname == "dis_ip_p_inc_sum"
		
		capture drop if itt_noctrl == "NA"
		destring itt_noctrl, replace
		gen itt_noctrlre = itt_noctrl
		summ itt_noctrl if draw == 0 & ddraw == 0
		local est = r(mean)
		summ    itt_noctrl                                 
		gen     itt_noctrl_mean = r(mean)             
		replace itt_noctrl = itt_noctrl - itt_noctrl_mean`num'
			
		gen     itt_noctrl_ind = 1 
		replace itt_noctrl_ind = 0 if (`est' > itt_noctrl)
			
		summ itt_noctrl_ind
		gen itt_noctrl_p = r(mean)
		keep if draw == 0 & ddraw == 0
		gen  sexnum = `sexnum'
		order itt_noctrlre itt_noctrl_p sexnum
		keep itt_noctrlre itt_noctrl_p sexnum
		rename itt_noctrlre itt_ctrl
		mkmat *, matrix(`group'_`sex')
	}
}

cd $output
foreach sex in pooled {
	matrix allest`sex'          = [no_sibling_`sex' \ yes_sibling_`sex']
	matrix colnames allest`sex' = itt ittp sexnum
 	clear
	svmat allest`sex', names(col)
	sort sexnum
	gen  varind = _n
	replace itt = itt/1000
	
	#delimit
	twoway (bar itt varind if sexnum == 1, color(gs8) barwidth(.9))
	       (bar itt varind if sexnum == 2, color(gs4) barwidth(.9))
	       (scatter itt varind if ittp <= .10, msymbol(circle) mlwidth(medthick) mlcolor(black) mfcolor(black) msize(large))
		, 
		legend(cols(3) order(1 "No Siblings at Baseline" 2 "> 0 Siblings at Baseline" 3 "p-value {&le} .10") size(small))
			  xlabel(1 " " 2 " ", angle(45) noticks grid glcolor(gs14) labsize(small)) 
			  ylabel(0[20]100, angle(h) glcolor(gs14))
			  xtitle(" ",) 
			  ytitle("Treatment Effect on Parental Income (1000s of 2014 USD)", size(small))
			  graphregion(color(white)) plotregion(fcolor(white));
	#delimit cr
	graph export abccare_pincomesum_s`sex'.eps, replace
	
}
