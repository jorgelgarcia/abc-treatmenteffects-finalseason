version 12.0
set more off
clear all
set matsize 11000
set maxvar  32000

/*
Project :       ABC, CARE Treatment Effects / CBA
Description:    this .do file investigates the IRR/BC distributions
*This version:  July 7, 2015
*This .do file: Jorge L. Garcia
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
global data       = "$klmmexico/abccare/irr_ratios/jul-30b"
// output
global output     = "$projects/abc-treatmenteffects-finalseason/output/"

// pool etimates
cd $data
set obs 16875
gen b = _n

# delimit
global CBAComponents all cc costs crime diclaim edu health health_private health_public
                     inc_labor inc_parent inc_trans_pub qaly ssclaim ssiclaim transfer;

# delimit cr

matrix vall = J(1,8,.)
matrix colnames vall = estimate sex part p10 p90 m se pval
local se = 0
foreach estimate of numlist 2 5 8 {
	local se = `se' + 1
	insheet using npv_type`estimate'.csv, clear
	encode type, gen(typen)
	levelsof typen, local(testimates)
	local sn = 0
	foreach sex in f m p {
		local sn = `sn' + 1
		local sp = 0
		foreach part in $CBAComponents {
			local sp = `sp' + 1
			foreach type in `testimates' {
				summ value if sex == "`sex'" & part == "`part'" & typen == `type'
				matrix v`sex'`part'`type'_`estimate' = r(mean)
			}
		matrix v`sex'`part'_`estimate' = [`se',`sn',`sp',v`sex'`part'1_`estimate',v`sex'`part'2_`estimate',v`sex'`part'3_`estimate',v`sex'`part'4_`estimate',v`sex'`part'5_`estimate']
		matrix colnames v`sex'`part'_`estimate' = estimate sex part p10 p90 m se pval
		mat_rapp vall : vall v`sex'`part'_`estimate'
		}
	}
}

mat vall = vall[2...,1...]
clear
svmat vall, names(col)
keep if part == 1  | part == 2 | part == 3 | part == 4 | part == 6 | part == 7 | part == 8 /// 
      | part == 10 | part == 11 | part == 13

gen     ind = 1  if part == 3   
replace ind = 5  if part == 2
replace ind = 9  if part == 6 
replace ind = 13 if part == 11 
replace ind = 17 if part == 10
replace ind = 21 if part == 8
replace ind = 25 if part == 7
replace ind = 29 if part == 13
replace ind = 34 if part == 4 
replace ind = 39 if part == 1

replace ind = ind + 1 if estimate == 2
replace ind = ind + 2 if estimate == 3 

replace pval = 1 - pval if m < 0
gen sig = 1 if pval <= .13
replace sig = . if estimate == 2 & part == 2

replace m = m/100000
replace m = m/10 if ind >= 34

cd $output
foreach sex of numlist 3 {
	#delimit
	twoway (bar m ind        if estimate == 1 & sex == `sex', fcolor(white) lcolor(gs0) lwidth(medthick) text(-.12 37.5 "In 1,000,000s (2014 USD)", size(vsmall)))
	       (bar m ind        if estimate == 2 & sex == `sex', color(gs4) xline(32.5, lcolor(gs10) lpattern(dash)))
	       (bar m ind        if estimate == 3 & sex == `sex', color(gs8))
	       (scatter m ind if sig == 1 & sex == `sex', msymbol(circle) mlwidth(medthick) mlcolor(black) mfcolor(black) msize(small))
		, 
		legend(cols(3) order(1 "Baseline" 2 "Stay at Home" 3 "Alternative Preschool" 
					    4 "Signicant at 10%") size(vsmall))
			  xlabel(2 "Program Costs" 6 "Control Substitution" 10 "Education" 14 "Parental Income"
			  18 "Labor Income" 22 "Private Medical Costs" 26 "Total Medical Costs" 30 "QALYs" 35 "Crime" 40 "All", angle(45) noticks grid glcolor(white) labsize(small)) 
			  ylabel(-1[.5]2, angle(h) glcolor(gs14))
			  xtitle(Cost Benefit Analysis Components, size(small)) 
			  ytitle("100,000's (2014 USD)")
			  graphregion(color(white)) plotregion(fcolor(white));
	#delimit cr 
	graph export abccare_npvs`estimate'.eps, replace
}		
