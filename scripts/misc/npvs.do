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
global data       = "$klmmexico/abccare/irr_ratios/jul-30"
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
keep if part == 1 | part == 6 | part == 10 | part == 11 | part == 16 | part == 7 | part == 13 | part == 4

gen     ind = 1  if part == 6   
replace ind = 5  if part == 11
replace ind = 9  if part == 10 
replace ind = 13 if part == 16 
replace ind = 17 if part == 7 
replace ind = 21 if part == 13 
replace ind = 26 if part == 4
replace ind = 30 if part == 1 

replace ind = 2  if part == 6  & sex == 2
replace ind = 6  if part == 11 & sex == 2
replace ind = 10 if part == 10 & sex == 2
replace ind = 14 if part == 16 & sex == 2
replace ind = 18 if part == 7  & sex == 2
replace ind = 22 if part == 13 & sex == 2
replace ind = 27 if part == 4  & sex == 2 
replace ind = 31 if part == 1  & sex == 2

replace ind = 3  if part == 6  & sex == 3
replace ind = 7  if part == 11 & sex == 3
replace ind = 11 if part == 10 & sex == 3
replace ind = 15 if part == 16 & sex == 3
replace ind = 19 if part == 7  & sex == 3
replace ind = 23 if part == 13 & sex == 3
replace ind = 28 if part == 4  & sex == 3 
replace ind = 32 if part == 1  & sex == 3

replace pval = 1 - pval if m < 0
gen sig = 1 if pval <= .10

replace m = m/100000
replace m = m/10 if ind >= 24 & ind <= 32

cd $output
foreach estimate of numlist 1 2 3 {
	#delimit
	twoway (bar m ind        if estimate == `estimate' & sex == 1, fcolor(white) lcolor(gs0) lwidth(medthick) text(-.13 29 "(In 1,000,000's 2014 USD)", size(small)))
	       (bar m ind        if estimate == `estimate' & sex == 2, color(gs4) xline(24.3, lcolor(gs10) lpattern(dash)))
	       (bar m ind        if estimate == `estimate' & sex == 3, color(gs8))
	       (scatter m ind if sig == 1 & estimate == `estimate', msymbol(circle) mlwidth(medthick) mlcolor(black) mfcolor(black) msize(small))
		, 
		legend(cols(3) order(1 "Female" 2 "Female" 3 "Pooled" 
					    4 "Signicant at 10%") size(vsmall))
			  xlabel(2 "Education" 6 "Parental Income" 10 "Labor Income" 14 "Public Transfers"
			  18 "Medical Expenditures" 22 "QALYs" 27 "Crime" 31 "All", angle(45) noticks grid glcolor(white) labsize(small)) 
			  ylabel(, angle(h) glcolor(gs14))
			  xtitle(Cost Benefit Analysis Components, size(small)) 
			  ytitle("Life-cycle Net Present Value (100,000's 2014 USD)", size(vsmall))
			  graphregion(color(white)) plotregion(fcolor(white));
	#delimit cr 
	graph export abccare_npvs`estimate'.eps, replace
}		
