version 12.0
set more off
clear all
set matsize 11000
set maxvar  32000

/*
Project :       ABC, CARE Treatment Effects / CBA
Description:    plot NPVS
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
global data       = "$klmmexico/abccare/irr_ratios/current/"
global specialed  = "$klmmexico/abccare/NPV/speccost/current/"

// output
global output     = "$projects/abc-treatmenteffects-finalseason/output/"

// rates of return
local te3 = 13
local sh3 = 9
local ap3 = 13 

local te2 = 15
local sh2 = 8
local ap2 = 16

local te1 = 10
local sh1 = 13
local ap1 = 9

// y labels
global ylabel1 -2[1]4 
global ylabel2 -2[2]10
global ylabel3 -2[1]5

// pool etimates
cd $data
set obs 16875
gen b = _n

# delimit
global CBAComponents all cc costs crime diclaim edu health health_private health_public
                     inc_labor inc_parent inc_trans_pub m_ed qaly ssclaim ssiclaim transfer;

# delimit cr

matrix vall = J(1,7,.)
matrix colnames vall = estimate sex part m point pval se
local se = 0
foreach estimate of numlist 2 5 8 {
	local se = `se' + 1
	cd $data/type`estimate'
	insheet using npv_type`estimate'.csv, clear
	drop if type == "0.1" | type == "0.9"
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
		matrix v`sex'`part'_`estimate' = [`se',`sn',`sp',v`sex'`part'1_`estimate',v`sex'`part'2_`estimate',v`sex'`part'3_`estimate',v`sex'`part'4_`estimate']
		matrix colnames v`sex'`part'_`estimate' = estimate sex part m point pval se
		mat_rapp vall : vall v`sex'`part'_`estimate'
		}
	}
}

mat vall = vall[2...,1...]
clear
svmat vall, names(col)
keep if part == 1 | part == 3 | part == 4 | part == 6 | part == 7 | part == 10 | part == 11 | part == 14

gen part1 = .
// replace part1 = 1 if part == 3
replace part1 = 1 if part == 3 
replace part1 = 2 if part == 10
replace part1 = 3 if part == 11
replace part1 = 4 if part == 4 
replace part1 = 5 if part == 14

replace pval = 1 - pval if m < 0
gen sig = 1 if pval <= .15

replace m = m/100000
gen part0 = part1 - .215
gen part2 = part1 + .215

gen part00 = part0 - .1
gen part11 = part1 - .1 
gen part22 = part2 - .1

gen mm = m
format %9.1f mm


cd $output
# delimit
twoway 
       (bar     m part0            if estimate == 1 & sex == 1, color(dkorange) barw(.2))
       (bar     m part1            if estimate == 1 & sex == 3, fcolor(none) lcolor(gs0) lwidth(medthick) barw(.21))
       (bar     m part2            if estimate == 1 & sex == 2, color(emerald) barw(.2))
       (scatter m part1 if sig == 1 & estimate == 1 & sex == 3, msymbol(circle) mlwidth(medthick) mlcolor(black) mfcolor(black) msize(small))
       (scatter m part0 if sig == 1 & estimate == 1 & sex == 1, msymbol(circle) mlwidth(medthick) mlcolor(black) mfcolor(black) msize(small))
       (scatter m part2 if sig == 1 & estimate == 1 & sex == 2, msymbol(circle) mlwidth(medthick) mlcolor(black) mfcolor(black) msize(small))
       
       (scatter mm part00 if estimate == 1 & sex == 1, msym(none) mlab(mm) mlabcol(black) mlabpos(1) mlabsize(vsmall))
       (scatter mm part11 if estimate == 1 & sex == 3, msym(none) mlab(mm) mlabcol(black) mlabpos(1) mlabsize(vsmall))
       (scatter mm part22 if estimate == 1 & sex == 2, msym(none) mlab(mm) mlabcol(black) mlabpos(1) mlabsize(vsmall))
		, 
		legend(cols(4) order(1 "Females" 2 "Females and Males" 3 "Males" 4 "Significant at 10%") position(north) size(vsmall))
			  xlabel(1 "Program Costs" 2 "Labor Income" 3 "Parental Labor Income"
			  4 "Crime" 5 "{&lowast}QALYs",  angle(h) noticks grid glcolor(gs14) labsize(vsmall)) 
			  ylabel(-1 0[2.5]7.5, angle(h) glcolor(gs14))
			  xtitle("", size(small)) 
			  ytitle("100,000's (2014 USD)")
			  graphregion(color(white)) plotregion(fcolor(white))
			  note("Per-annum Rate of Return: Males and Females 13.7% (s.e. 3%); Males 14.6% (s.e. 4%); Females 10% (s.e. 8%)." " "
			       "Benefit-cost Ratio: Males and Females 7.3 (s.e. 1.8); Males 10.2 (s.e. 2.9); Females 2.6 (s.e. .73)."
			        , size(vsmall));
#delimit cr 
graph export abccare_npvssumm.eps, replace

drop part0* part1* part2* 

gen part1 = .
// replace part1 = 1 if part == 3
replace part1 = 1 if part == 3 
replace part1 = 2 if part == 10
replace part1 = 3 if part == 11
replace part1 = 4 if part == 4 
replace part1 = 5 if part == 14
replace part1 = 6 if part == 1

gen part0 = part1 - .215
gen part2 = part1 + .215

gen part00 = part0 - .12
gen part11 = part1 - .12 
gen part22 = part2 - .12

cd $output
# delimit
twoway 
       (bar     m part0            if estimate == 1 & sex == 1, color(dkorange) barw(.2))
       (bar     m part1            if estimate == 1 & sex == 3, fcolor(none) lcolor(gs0) lwidth(medthick) barw(.21))
       (bar     m part2            if estimate == 1 & sex == 2, color(emerald) barw(.2))
       (scatter m part1 if sig == 1 & estimate == 1 & sex == 3, msymbol(circle) mlwidth(medthick) mlcolor(black) mfcolor(black) msize(small))
       (scatter m part0 if sig == 1 & estimate == 1 & sex == 1, msymbol(circle) mlwidth(medthick) mlcolor(black) mfcolor(black) msize(small))
       (scatter m part2 if sig == 1 & estimate == 1 & sex == 2, msymbol(circle) mlwidth(medthick) mlcolor(black) mfcolor(black) msize(small))
       
       (scatter mm part00 if estimate == 1 & sex == 1, msym(none) mlab(mm) mlabcol(black) mlabpos(1) mlabsize(vsmall))
       (scatter mm part11 if estimate == 1 & sex == 3, msym(none) mlab(mm) mlabcol(black) mlabpos(1) mlabsize(vsmall))
       (scatter mm part22 if estimate == 1 & sex == 2, msym(none) mlab(mm) mlabcol(black) mlabpos(1) mlabsize(vsmall))
		, 
		legend(cols(4) order(1 "Females" 2 "Females and Males" 3 "Males" 4 "Significant at 10%") position(north) size(vsmall))
			  xlabel(1 "Program Costs" 2 "Labor Income" 3 "Parental Labor Income"
			  4 "Crime" 5 "{&lowast}QALYs" 6 "Total Benefits",  angle(h) noticks grid glcolor(gs14) labsize(vsmall)) 
			  ylabel(-1 0[2.5]10, angle(h) glcolor(gs14))
			  xtitle("", size(small)) 
			  ytitle("100,000's (2014 USD)")
			  graphregion(color(white)) plotregion(fcolor(white))
			  note("Per-annum Rate of Return: Males and Females 13.7% (s.e. 3%); Males 14.6% (s.e. 4%); Females 10% (s.e. 8%)." " "
			       "Benefit-cost Ratio: Males and Females 7.3 (s.e. 1.8); Males 10.2 (s.e. 2.9); Females 2.6 (s.e. .73)."
			        , size(vsmall));
#delimit cr 
graph export abccare_npvssumm_alt.eps, replace







